syn clear
syn match gvTree    /^[^a-f0-9]* / nextgroup=gvInfo
syn match gvAnsiIgnore1    /\e\[[0-9;]*[mK]|\e\[m/ conceal cchar=|
syn match gvAnsiIgnore2    /\e\[[0-9;]*[mK]\/\e\[m/ conceal cchar=/
syn match gvAnsiIgnore3    /\e\[[0-9;]*[mK]\\\e\[m/ conceal cchar=\
syn match gvAnsiIgnore4    /\e\[[0-9;]*[mK]_\e\[m/ conceal cchar=_
syn match gvInfo    /[a-f0-9]\+ / contains=gvSha nextgroup=gvMetaMessage,gvMessage
syn match gvSha     /[a-f0-9]\{6,}/ contained
syn match gvMetaMessage /.* \ze(.\{-})$/ contained contains=gvAuthorMeta,gvGitHub,gvJira nextgroup=gvMeta
syn match gvMessage /.*) $/ contained contains=gvAuthorOnly,gvGitHub,gvJira
syn match gvAuthorMeta    /([^)]\+)[ ]\+([^)]\+)$/ contained contains=gvAuthor,gvMeta
syn match gvAuthorOnly    /([^)]\+) $/ contained contains=gvAuthor
syn match gvAuthor    /([^()]\+) / contained contains=gvAuthorName
syn match gvAuthorName  /(\zs[^(),]\+\ze,/ contained
syn match gvMeta    /([^)]\+)$/ contained contains=gvTag
syn match gvTag     /(tag:[^)]\+)/ contained
syn match gvGitHub  /\<#[0-9]\+\>/ contained
syn match gvJira    /\<[A-Z]\+-[0-9]\+\>/ contained
hi def link gvTree       Comment
hi def link gvSha        Identifier
hi def link gvTag        Conditional
hi def link gvGitHub     Label
hi def link gvJira       Label
hi def link gvMeta       Conditional
hi def link gvAuthor     String
hi def link gvAuthorName Function

syn match gvAdded     "^\W*\zsA\t.*"
syn match gvDeleted   "^\W*\zsD\t.*"
hi def link gvAdded    diffAdded
hi def link gvDeleted  diffRemoved

syn match diffAdded   "^+.*"
syn match diffRemoved "^-.*"
syn match diffLine    "^@.*"
syn match diffFile    "^diff\>.*"
syn match diffFile    "^+++ .*"
syn match diffNewFile "^--- .*"
hi def link diffFile    Type
hi def link diffNewFile diffFile
hi def link diffAdded   Identifier
hi def link diffRemoved Special
hi def link diffFile    Type
hi def link diffLine    Statement

hi def link gvAnsi1 Keyword
hi def link gvAnsi2 String
hi def link gvAnsi3 Type
hi def link gvAnsi4 Variable
hi def link gvAnsi5 Constant
hi def link gvAnsi6 Include
hi def link gvAnsi7 Operator
hi def link gvAnsi9 Comment

setlocal conceallevel=1
setlocal concealcursor=nvc
