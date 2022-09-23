# Rate My Pulls

[![Continous Integration](https://github.com/ananthb/rate-my-pulls/actions/workflows/ci.yaml/badge.svg)](https://github.com/ananthb/rate-my-pulls/actions/workflows/ci.yaml) [![OCI Container Images](https://github.com/ananthb/rate-my-pulls/actions/workflows/images.yaml/badge.svg)](https://github.com/ananthb/rate-my-pulls/actions/workflows/images.yaml)

Tinder for your pull requests.

A GitHub app that lets you swipe through code from the users you follow.
Match with a user if you've swiped right on their code and vice-versa.


## Builds

### Container

```shell
# build contaimer image
podman build -t rate-my-pulls .

# copy and edit environment
cp env.default env

# run the container
podman run --rm --name rate-my-pulls -p 8000:8000 --env-file env rate-my-pulls
```

### Linux

Dependencies:
1. python 3.10 or greater
2. nodejs 18 or greater
3. poetry
4. rust stable

```shell
# build Elm app
npm install
npm run build

# start development server
npm start

# install python dependencies
poetry install

# setup environment
# don't forget to edit env
cp env.default env

# run the python app
poetry run rmp
```


## URLs

- Website - [rate-my-pulls.fly.dev](https://rate-my-pulls.fly.dev)
- Source Hut Mirror - [git.sr.ht/~ananth/rate-my-pulls](https://git.sr.ht/~ananth/rate-my-pulls)


## Acknowledgements

### [NES.css](https://github.com/nostalgic-css/NES.css) 

NES.css is an NES-style CSS Framework. NES.css is licensed under the MIT license.

Copyright 2018 B.C.Rikko.

### [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P)

Press Start 2P is a bitmap font based on the font design from 1980s Namco Arcade games.
Press Start 2P is licensed under the [Open Font License](https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL).

Press Start 2P is designed by Cody "CodeMan38" Boisclair.


## COPYING

Rate My Pulls is licensed under AGPL-3.0-only.
The full text of the license is available in the [COPYING](COPYING) file.

Copyright 2022, Ananth <rate-my-pulls@kedi.dev>

