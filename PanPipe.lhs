> module PanPipe where

> import Control.Applicative
> import Data.List
> import System.IO.Temp (withSystemTempDirectory)
> import System.Process
> import Text.Pandoc
> import Text.Pandoc.Shared (inDirectory)
> import Text.Pandoc.Walk (walkM)

> pipeBWith :: (Functor m, Monad m) => (String -> String -> m String)
>                                   -> Block
>                                   -> m Block
> pipeBWith f (CodeBlock as s)
>           |  Just (as', p) <- partPipes as = CodeBlock as' <$> f p s
> pipeBWith f x = walkM (pipeIWith f) x

> pipeB = pipeBWith readShell

> pipeIWith :: (Functor m, Monad m) => (String -> String -> m String)
>                                   -> Inline
>                                   -> m Inline
> pipeIWith f (Code as s)
>           |  Just (as', p) <- partPipes as = Code as' <$> f p s
> pipeIWith f x = return x

> pipeI = pipeIWith readShell

> readShell :: FilePath -> String -> IO String
> readShell p s = readProcess "sh" ["-c", p] s

> partPipes :: Attr -> Maybe (Attr, String)
> partPipes (x, y, zs) = case partition (("pipe" ==) . fst) zs of
>                             ((_, p):_, zs') -> Just ((x, y, zs'), p)
>                             _               -> Nothing

> transform :: Pandoc -> IO Pandoc
> transform doc = withSystemTempDirectory "panpipe" $ (`inDirectory` transformDoc doc)

Use Pandoc to parse, traverse and pretty-print our documents

> transformDoc :: Pandoc -> IO Pandoc
> transformDoc = walkM pipeB

> readDoc :: String -> Pandoc
> readDoc = readMarkdown def

> writeDoc :: Pandoc -> String
> writeDoc = writeMarkdown def

> processDoc :: String -> IO String
> processDoc = fmap writeDoc . transform . readDoc
