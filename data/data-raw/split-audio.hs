#!/usr/bin/env stack
{- stack script --resolver lts-mpg123.yaml
   --optimize --ghc-options -threaded
   --package aeson
   --package async
   --package bytestring
   --package cassava
   --package conduit
   --package conduit-audio
   --package conduit-audio-mpg123
   --package conduit-audio-sndfile
   --package directory
   --package filepath
   --package formatting
   --package hsndfile
   --package hsndfile-vector
   --package mpg123-bindings
   --package optparse-applicative
   --package process
   --package resourcet
   --package text
-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Control.Concurrent.Async (mapConcurrently)
import Control.Monad.Trans.Resource (ResourceT, runResourceT)
import Data.Aeson ( FromJSON
                  , (.:)
                  , eitherDecodeStrict
                  , parseJSON
                  , parseJSONList
                  , withObject
                  )
import Data.ByteString.Lazy (putStr)
import Data.Conduit.Audio ( AudioSource
                          , Duration(Seconds)
                          , Seconds
                          , dropStart
                          , takeStart
                          )
import Data.Conduit.Audio.Mpg123 (sourceMpg)
import Data.Conduit.Audio.Sndfile (sinkSnd)
import Data.Csv ( DefaultOrdered
                , ToNamedRecord
                , (.=)
                , encodeDefaultOrderedByName
                , headerOrder
                , namedRecord
                , toNamedRecord
                )
import Data.Either (rights)
import Data.Foldable (traverse_)
import Data.Int (Int16)
import Data.List (sort)
import Data.Maybe (catMaybes)
import Data.Text (Text, breakOn, pack, replace, unpack)
import Data.Text.Encoding (encodeUtf8)
import Data.Text.IO (readFile)
import Data.Traversable (traverse)
import Formatting ((%.), sformat, int, left)
import Options.Applicative ( Parser
                           , ParserInfo
                           , (<**>)
                           , execParser
                           , fullDesc
                           , helper
                           , info
                           , metavar
                           , strArgument
                           )
import Sound.File.Sndfile ( Format(Format)
                          , HeaderFormat(HeaderFormatWav)
                          , SampleFormat(SampleFormatPcm16)
                          , EndianFormat(EndianFile)
                          )
import System.Directory (doesDirectoryExist, listDirectory, removeFile)
import System.FilePath ((</>) , (-<.>) , takeBaseName , takeFileName)
import System.Process (ProcessHandle, spawnProcess, waitForProcess)
import Prelude hiding (LT, putStr, readFile)

import qualified Data.Csv as Csv (header)
import qualified Data.Text as Text (concat)
import qualified Options.Applicative as Opts (header)

{--- ARGUMENT PROCESSING ---}

data Args = Args
    { audioDir :: !FilePath
    , jamsDir  :: !FilePath
    , outDir   :: !FilePath
    } deriving (Show)

argsP :: Parser Args
argsP = Args
    <$> strArgument (metavar "AUDIO_DIR")
    <*> strArgument (metavar "JAMS_DIR")
    <*> strArgument (metavar "OUTPUT_DIR")

argsInfo :: ParserInfo Args
argsInfo = info
           (argsP <**> helper)
           (Opts.header "Split MASF-segmented MP3s" <> fullDesc)


{-- SEGMENT PARSING --}

data Country =
      AL | AD | AM | AU | AT | AZ | BY | BE | BA | BG
    | HR | CY | CZ | DK | EE | FI | FR | GE | DE | GR
    | HU | IS | IE | IL | IT | LV | LT | LU | MT | MD
    | MC | ME | MA | NL | MK | NO | PL | PT | RO | RU
    | SM | RS | CS | SK | SI | ES | SE | CH | TR | UA
    | GB | YU
    deriving (Ord, Enum, Eq, Read, Show)

fromText :: Text -> Country
fromText "Albania" = AL
fromText "Andorra" = AD
fromText "Armenia" = AM
fromText "Australia" = AU
fromText "Austria" = AT
fromText "Azerbaijan" = AZ
fromText "Belarus" = BY
fromText "Belgium" = BE
fromText "Bosnia & Herzegovina" = BA
fromText "Bulgaria" = BG
fromText "Croatia" = HR
fromText "Cyprus" = CY
fromText "Czech Republic" = CZ
fromText "Denmark" = DK
fromText "Estonia" = EE
fromText "Finland" = FI
fromText "France" = FR
fromText "Georgia" = GE
fromText "Germany" = DE
fromText "Greece" = GR
fromText "Hungary" = HU
fromText "Iceland" = IS
fromText "Ireland" = IE
fromText "Israel" = IL
fromText "Italy" = IT
fromText "Latvia" = LV
fromText "Lithuania" = LT
fromText "Luxembourg" = LU
fromText "Malta" = MT
fromText "Moldova" = MD
fromText "Monaco" = MC
fromText "Montenegro" = ME
fromText "Morocco" = MA
fromText "Netherlands" = NL
fromText "North MacedoniaNorth MacedoniaN.Macedonia" = MK
fromText "Norway" = NO
fromText "Poland" = PL
fromText "Portugal" = PT
fromText "Romania" = RO
fromText "Russia" = RU
fromText "San Marino" = SM
fromText "Serbia" = RS
fromText "Serbia & Montenegro" = CS
fromText "Slovakia" = SK
fromText "Slovenia" = SI
fromText "Spain" = ES
fromText "Sweden" = SE
fromText "Switzerland" = CH
fromText "Turkey" = TR
fromText "Ukraine" = UA
fromText "United KingdomUK" = GB
fromText "Yugoslavia" = YU

data Segment = Segment { startTime :: !Seconds
                       , duration  :: !Seconds
                       } deriving (Eq, Ord, Show)
instance FromJSON Segment where
    parseJSON = withObject "Segment" $ \v -> Segment
                                             <$> v .: "time"
                                             <*> v .: "duration"
    parseJSONList = withObject "JAMS" $ \v -> do
        annotations <- v .: "annotations"
        dat <- (head annotations) .: "data"
        traverse parseJSON dat

data Track = Track { year     :: !Integer
                   , country  :: !Country
                   , mp3      :: !Text
                   , segments :: [Segment]
                   } deriving (Eq, Ord, Show)

data TrackSegment = TrackSegment { trackYear        :: !Integer
                                 , trackCountry     :: !Country
                                 , trackMP3         :: !Text
                                 , segmentStartTime :: !Seconds
                                 , segmentDuration  :: !Seconds
                                 } deriving (Show)
instance ToNamedRecord TrackSegment where
    toNamedRecord (TrackSegment yr cn m st dr) =
        namedRecord [ "year"       .= yr
                    , "country"    .= show cn
                    , "start_time" .= st
                    , "duration"   .= dr
                    ]
instance DefaultOrdered TrackSegment where
    headerOrder _ =
        Csv.header ["year", "country", "start_time", "duration"]

eitherDecodeJAMS :: FilePath -> IO (Either String [Segment])
eitherDecodeJAMS fp =
    eitherDecodeStrict
    <$> encodeUtf8
    <$> replace "Infinity" "null" <$> replace "-Infinity" "null"
    <$> readFile fp

eitherDecodeTrack :: Args -> FilePath -> FilePath -> IO (Either String Track)
eitherDecodeTrack args y fp =
    let country = fromText $ fst $ breakOn "_" $ pack $ takeBaseName fp
        mp3 = pack $ takeFileName $ fp -<.> "mp3"
    in do eitherJAMS <- eitherDecodeJAMS $ (audioDir args) </> y </> fp
          case eitherJAMS of
              Left s -> return $ Left s
              Right jaml -> return $ Right $ Track (read y) country mp3 jaml

toTrackSegments :: Track -> [TrackSegment]
toTrackSegments t =
    let ts s = TrackSegment
               (year t) (country t) (mp3 t)
               (startTime s) (duration s)
    in fmap ts (segments t)

{--- AUDIO PROCESSING ---}

processSegment :: Args
               -> (AudioSource (ResourceT IO) Int16)
               -> TrackSegment
               -> IO (Maybe ProcessHandle)
processSegment args audioIn seg =
    if (segmentDuration seg) > 5.0
    then let audioOut =
                 takeStart (Seconds $ segmentDuration seg) $
                 dropStart (Seconds $ segmentStartTime seg) audioIn
             wav = Format HeaderFormatWav SampleFormatPcm16 EndianFile
             wavPath = (outDir args) </>
                        (concat [ show $ trackYear seg
                                , "-" , show $ trackCountry seg
                                , "-" , unpack $
                                        sformat (left 3 '0' %. int) $
                                        round $
                                        segmentStartTime seg
                                , ".wav"
                                ])
             jsonPath = wavPath -<.> "json"
         in do runResourceT $ sinkSnd wavPath wav audioOut
               h <- spawnProcess "streaming_extractor_music" [wavPath, jsonPath]
               return $ Just h
    else return Nothing

processTrack :: Args -> Track -> IO ()
processTrack args t =
    let mp3Path = (audioDir args) </> (show $ year t) </> (unpack $ mp3 t)
    in do audioIn <- sourceMpg mp3Path
          hs <- traverse (processSegment args audioIn) $ toTrackSegments t
          traverse_ waitForProcess $ catMaybes hs

{--- MAIN FUNCTION ---}

processYear :: Args -> FilePath -> IO [Track]
processYear args y =
    do exists <- doesDirectoryExist dir
       if exists
           then do fps <- listDirectory $ dir
                   eitherTracks <-
                       traverse (eitherDecodeTrack args y) $ (dir </>) <$> fps
                   return $ rights eitherTracks
           else return []
         where dir = (jamsDir args) </> y

main :: IO ()
main = do args <- execParser argsInfo
          years <- listDirectory $ audioDir args
          tracks <- concat <$> mapConcurrently (processYear args) years
          traverse_ (processTrack args) tracks
          putStr
              $ encodeDefaultOrderedByName
              $ concat
              $ toTrackSegments
              <$> (sort tracks)
