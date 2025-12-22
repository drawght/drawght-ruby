# Drawght

Drawght (like draft/draught) is a data handler for texts without logical
statements. The goal is to use a dataset (such as the subject of a text) to
draft a document template. It can be considered a mini template processor.

Data is accessed through `{}` braces, replaced by their respective values.

Considering the following data:

```yaml
title: Drawght is a very useful sketch
author:
  name: Hallison Batista
  email: email@hallison.dev.br
  networks:
  - name: Github
    url: //github.com/hallison
  - name: Twitter
    url: //twitter.com/hallison
creation-date: 2021-06-28
publishing date: 2021-07-01
references:
- name: Mustache
  url: //mustache.github.io
- name: Handlebars
  url: //handlebarsjs.com
tags:
- Template
- Draft
```

Note that the `creation-date` and `publishing date` fields are normally
identified by the parser.

In a template written in Markdown: 

```markdown
# {title}

Drawght is a good tool for writing draft documents using datasets without
logical statements.

Written by {author.name} <{author.email}>, created in {creation-date},
published in {publishing date} and tagged by {tags#1}.

- [{author.networks:name}]({author.networks:url})

Follow the news on [{author.networks#1.name}]({author.networks#1.url}).

The syntax was inspired by: 

- [{references:name}]({references:url})

Tags:

- {tags} (tagged by {author.name}).
```

The Drawght processing returns the following result:

```markdown
# Drawght is a very useful sketch

Drawght is a good tool for writing draft documents using datasets without
logical statements.

Written by Hallison Batista <email@hallison.dev.br>, created in 2021-06-28,
published in 2021-07-01 and tagged by Template.

- [Dev.to](//dev.to/hallison)
- [Github](//github.com/hallison)
- [Twitter](//twitter.com/hallison)

Follow the news on [Dev.to](//dev.to/hallison).

The syntax was inspired by:

- [Mustache](//mustache.github.io)
- [Handlebars](//handlebarsjs.com)

Tags:

- Template (tagged by Hallison Batista).
- Draf (tagged by Hallison Batista).
```

In a template written in HTML: 

```html
<h1>{title}</h1>

<p>
Drawght is a good tool for writing draft documents using datasets without
logical statements.
</p>

<p>
Written by <a href="mailto:{author.email}">{author.name}</a>, created
published in {publishing date} and tagged by {tags#1}.
</p>

<ul>
  <li><a href="{author.networks:url}">{author.networks:name}</a></li>
</ul>

<p>
Follow the news on <a href="{author.networks#1.url}">author.networks#1.name</a>.
</p>

<p>
The syntax was inspired by: 
</p>

<ul>
  <a href="{references:url}">{references:name}</a>
</ul>

<p>
Tags:
</p>

<ul>
  <li>{tags} (tagged by {author.name}).</li>
</ul>
```

The Drawght processing returns the following result:

```html
<h1>Drawght is a very useful sketch</h1>

<p>
Drawght is a good tool for writing draft documents using datasets without
logical statements.
</p>

<p>
Written by <a href="mailto:email@hallison.dev.br">Hallison Batista</a>,
created published in 2021-07-01 and tagged by Template.
</p>

<ul>
  <li><a href="//dev.to/hallison">Dev.to</a></li>
  <li><a href="//github.com/hallison">Github</a></li>
  <li><a href="//twitter.com/hallison">Twitter</a></li>
</ul>

<p>
Follow the news on <a href="//dev.to/hallison">Dev.to</a>.
</p>

<p>
The syntax was inspired by:
</p>

<ul>
  <a href="//mustache.github.io">Mustache</a>
  <a href="//handlebarsjs.com">Handlebars</a>
</ul>

<p>
Tags:
</p>

<ul>
  <li>Template (tagged by Hallison Batista).</li>
  <li>Draf (tagged by Hallison Batista).</li>
</ul>
```

## Install

```bash
gem install drawght
```

## Usage

```ruby
require "drawght"

template = "{package.name} v{package.version}"
result = Drawght.compile template, {
  package: {
    name: "Drawght",
    version: "1.0.0",
  }
}

puts result
# Drawght v1.0.0
```

## Syntax

Drawght has a simple syntax:

- `{identifier}`: converts `identifier` to its respective value. If the value
  is a collection, then the row will be replicated and converted with the
  respective values.

- `{structure.attribute}`: converts `attribute` to its respective value inside
  `structure`, assuming the same behavior as `{identifier}`.

- `{collection:attribute}`: selects `collection`, replicates the line for each
  item in the collection, and converts `attribute` to its respective value
  contained in an structure within `collection`. The `collection` key can also
  be accessed by `structure.collection`, just as `attribute` can also be
  accessed by `structure.attribute` which will be converted following the same
  process in case it is a collection.

- `{collection#nth.attribute}`: selects the `nth` (start from 1) item from
  `collection` and converts `attribute` to its respective value. The whole
  process is similar to `structure.attribute`.

- `{collection#$.attribute}`: selects the `nth` (start from 1) item from
  `collection` and converts `attribute` to its respective value. The whole
  process is similar to `structure.attribute`.

### EBNF

```ebnf
identifier ::= initial_name { compound_name | space compound_name } ;

initial_name ::= letter | "_" ;

compound_name ::= letter | digit | "_" | "-" ;

letter ::= "A"…"Z" | "a"…"z" ;

digit ::= "0"…"9" ;

space ::= " " ;

expression ::= path [ length ] ;

path ::= [ structural_path ] { sequential_path } ;

structural_path ::= attribute { "." attribute } ;

scoped_path ::= ":" structural_path ;

attribute ::= element | item ;

element ::= identifier [ index ] ;

item ::= index ;

index ::= "#" ( number | "$" ) ;

number ::= digit { digit } ;

length ::= "#&" ;
```

## How it works

### Variables and attributes

#### Definition

```yaml
Author:
  Name: John Scalzi

Protagonist: John Perry
```

#### Usage

```
{Protagonist}
{Author.Name}
```

### Collections

#### Definition

```yaml
Book Titles:
- Old Man's War
- The Ghost Brigades
- The Last Colony

# Or

Books:
- Title: Old Man's War
- Title: The Ghost Brigades
- Title: The Last Colony
```

#### Usage

For value sequencing.

```
{Book Titles}
{Books:Title}
```

For value straightly.

```
{Book Titles#1}
{Book Titles#2}
{Book Titles#3}

{Books#1.Title}
{Books#2.Title}
{Books#3.Title}
```

### Nested collections

#### Definition

```yaml
Books:
- Title: Old Man's War
  ISBN: 0-7653-0940-8

- Title: The Ghost Brigades
  ISBN: 0-7653-1502-5

- Title: The Last Colony
  ISBN: 0-7653-1697-8

Series:
- Name: Old Man's War
  Books:
  - Title: Old Man's War
    ISBN: 0-7653-0940-8

  - Title: The Ghost Brigades
    ISBN: 0-7653-1502-5

  - Title: The Last Colony
    ISBN: 0-7653-1697-8

- Name: Lock In
  Books:
  - Title: Lock In
    ISBN: 978-0-7653-7586-5
  - Title: Head On
    ISBN: 978-0-7653-8891-9
```

#### Usage

```
{Books:Title}

{Books#1.Title}

{Series:Name}

{Series:Books:Title}

{Series#1.Name}

{Series#1.Books:Title}

{Series#2.Books#2.Title}
```

## License (MIT)

### Copyright (c) 2021-2025, Hallison Batista

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
