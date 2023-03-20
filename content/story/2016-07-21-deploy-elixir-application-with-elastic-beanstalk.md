---
date: 2016-07-21
title: Deploy Elixir application to AWS Elastic Beanstalk
tags:
  - elixir
  - exrm
  - edib
  - docker
  - aws
  - beanstalk
medium_link: https://medium.com/@fazibear/74e1bce100c6

image: /assets/images/stories/beanstalk.png
---

Lately I was playing with AWS. I'm just wondering how can I easily deploy Elixir application with Elastic Beanstalk.
Quickly I found [exrm](https://github.com/bitwalker/exrm). It's a great tool for generating elixir/erlang project releases. So I added to my deps in `mix.exs` something like this:

```elixir
{:exrm, "~> x.x.x"}
```

next step was generate a release:

```bash
$ mix deps.get
$ mix release
```

After a while new release was generated! So I want to deploy it!
ELastic Beanstalk supports docker. So let's generate one. Quickly find a proper `Dockerfile`:

```docker
FROM alpine:edge

RUN apk --update add erlang erlang-sasl erlang-crypto erlang-syntax-tools && rm -rf /var/cache/apk/*

ENV APP_NAME myapp
ENV APP_VERSION "0.0.1"
ENV PORT 4000

RUN mkdir -p /$APP_NAME
ADD rel/$APP_NAME/bin /$APP_NAME/bin
ADD rel/$APP_NAME/lib /$APP_NAME/lib
ADD rel/$APP_NAME/releases/start_erl.data                 /$APP_NAME/releases/start_erl.data
ADD rel/$APP_NAME/releases/$APP_VERSION/$APP_NAME.sh      /$APP_NAME/releases/$APP_VERSION/$APP_NAME.sh
ADD rel/$APP_NAME/releases/$APP_VERSION/$APP_NAME.boot    /$APP_NAME/releases/$APP_VERSION/$APP_NAME.boot
ADD rel/$APP_NAME/releases/$APP_VERSION/$APP_NAME.rel     /$APP_NAME/releases/$APP_VERSION/$APP_NAME.rel
ADD rel/$APP_NAME/releases/$APP_VERSION/$APP_NAME.script  /$APP_NAME/releases/$APP_VERSION/$APP_NAME.script
ADD rel/$APP_NAME/releases/$APP_VERSION/start.boot        /$APP_NAME/releases/$APP_VERSION/start.boot
ADD rel/$APP_NAME/releases/$APP_VERSION/sys.config        /$APP_NAME/releases/$APP_VERSION/sys.config
ADD rel/$APP_NAME/releases/$APP_VERSION/vm.args           /$APP_NAME/releases/$APP_VERSION/vm.args

EXPOSE $PORT

CMD trap exit TERM; /$APP_NAME/bin/$APP_NAME foreground & wait
```

Let's try build docker locally:

```bash
$ docker build -t myapp .
```

Wow, It build! Let's move on, and try to run it!

```bash
$ docker run -t myapp
```

Unfortunately my app using `hakey` and need and `ssl` stuff. After a lot of searching, I noticed that my release was build on mac. It simply will not work if there are packages that includes `erlang erts` etc.
After a while found another solution, that don't include this things in release. Added `rel/relx.config`:

```erlang
{include_erts, true}.
{include_src, false}.
```

Yes. It's `erlang` file, dots are necessary. But this solution also won't work. Tried added packages like `erlang-erts`, `erlang-asn1` into docker image, but without any luck. So it will not work. So I was thinking about creating a docker that will create release... Sounds interesting. But first let just run my elixir app on Beanstalk.

So I started to build another docker with following `Dockerfile`:

```docker
FROM msaraiva/elixir-dev

ENV APP_NAME myapp
ENV APP_VERSION "0.0.1.0"
ENV MIX_ENV prod

EXPOSE 80

RUN mkdir /$APP_NAME
ADD . /$APP_NAME/
WORKDIR /$APP_NAME

RUN ls -la

RUN mix deps.get
RUN mix deps.compile
RUN mix compile
RUN mix test
RUN mix do ecto.migrate

CMD mix server
```

Tired it local! Works. And on Beanstalk ?

```bash
$ eb deploy
```

Woow! Works. So I want to cleanup things a little. We don't need all this files in a docker image anyway.
I used `.dockerignore` file:

```
.git/
_build/
dist/
cover/
deps/
doc/
tarballs/
rel/
erl_crash.dump
*.ez
.edip.log

.*
```

OK, but what about Beanstalk ? Beanstalk use a `.ebignore` file witch can look exactly the same:

```
.git/
_build/
dist/
cover/
deps/
doc/
tarballs/
rel/
erl_crash.dump
*.ez
.edip.log

.*
```

So right now we send to Beanstalk only files that we need to build our docker image. BTW - Beanstalk don't ignore all files in deps folder. I don't know why, and really don't know why few files was send. I check it with `eb deploy --staged -v`. Nevermind!

Now everything works just fine, but this is very stupid thing. I don't need to upload source code of compiled language to server. I don't want to.

After a while [edib](https://github.com/asaaki/mix-edip) comes to rescue! This tool use `exrm` and `docker` to generate a proper release. This is what I was thinking of. Docker for building docker.

Great. Let's run it! Add another dependency to `mix.exs`:

```elixir
{:edib, "~> x.x.x"}
```

and let magic begins...

```bash
$ mix edib
```

Cool. Release generated, docker created! Now I can run it:

```
$ docker run --rm -e "PORT=4000" -p 4000:4000 local/myapp:0.0.0
```

It works. But how can I put it into Beanstalk ? I have a image `tar.gz` file in `tarballs` directory. But there must be a Dockerfile so beanstalk can create a proper image. OK lets try to build one:

```docker
FROM hackmann/empty

ENV APP_NAME myapp
ENV APP_VERSION "0.0.0"
ENV MIX_ENV prod
ENV ARCHIVE $APP_NAME-$APP_VERSION.tar.gz

EXPOSE 4000

ADD ./tarballs/$ARCHIVE /

CMD trap exit TERM; /app/bin/myapp foreground & wait
```

We have to start from scratch.

Interesting think is that Beanstalk don't allow us to create empty docker with `FROM scratch` directive, do I use one empty one. If you want to your docker image stays empty forever, you can create your own.

Next we need to add files from release archive to docker.
We can use `ADD` directive. It will unarchive it for us. Just wonderful isn't it ?

And yes it works on Beanstalk. You can deploy it with `eb deploy`. But wait. I have to cleanup our `.dockerignore` and `ebignore` files.
We only need `tarball` and `Dockerfile`. We can use `!` directive like this:

```
*
!tarballs/
!Dockerfile
```

First line will ignore all things, and just not ignore `tarballs` and `Dockerfile`

And that's it. We have a proper docker image only with compiled code. Also we have to remember that within release we don't have a `mix`. So things like `migration` will not work. There is a lot of solutions for that. Just google `exrm release migration`, you'll find a few.

Right now, deploying to `aws` is easy as deploying to `heroku`. You just type:

```bash
$ mix release
$ eb deploy
```

In the end I like to quote Borat:

> It's Very Nice!
