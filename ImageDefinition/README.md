# ImageDefinition Extractor

This subfolder builds a container to extract (and optionally deploy) an ImageDefinition.

# Usage
There are two ways you can use the extractors here!

## Local with Docker

The [Dockerfile](Dockerfile) is built and served on Docker Hub at 
[openschemas/extractors:ImageDefinition](https://cloud.docker.com/u/openschemas/repository/docker/openschemas/extractors). 
Specifically, it will take an input
Dockerfile, and use container-diff and Singularity Python Client (recipe parser)
to generate an html page embedded with json-ld, or just the json-ld, to
store with your recipe. Here is how to generate json-ld output to the console,
and then pipe it into a file:

```bash
# This is a really long name, use an environment variable CID for it
CID=openschemas/extractors:ImageDefinition

# Run using the Dockerfile inside the container (json-ld to terminal)
$ docker run -it ${CID} extract --contact vsoch

# Output html instead (renders into a nice web page)
$ docker run -it ${CID} extract --contact @vsoch --html

# Run with your own Dockerfile
$ docker run -v $PWD:/data -it ${CID} extract --contact vsoch --filename /data/Dockerfile

# Pipe into an output file
$ docker run -v $PWD:/data -it ${CID} extract --contact vsoch --filename /data/Dockerfile > metadata.json
```

Note that each of these commands will take about 
30 seconds to download the layers (with container-diff) to find software
dependencies. You can also customize some of the variables that go into the generation! We
do this by way of environment variables. Here is how to customize the image thumbnail (a web
address), the container description, a more detailed about, and the Github repository.

```bash
$ docker run -e IMAGE_THUMBNAIL=https://vsoch.github.io/datasets/assets/img/avocado.png \
             -e IMAGE_ABOUT="This Dockerfile was created by the avocado dinosaur." \
             -e GITHUB_REPOSITORY="openschemas/dockerfiles" \
             -e IMAGE_DESCRIPTION="ubuntu with golang and extra python modules installed." \
             -it openschemas/extractors:ImageDefinition extract --contact vsoch
```

The above variables default to the following:

| Variable | Default | 
|----------|---------|
| IMAGE_THUMBNAIL | 'https://vsoch.github.io/datasets/assets/img/avocado.png' |
| IMAGE_ABOUT | 'This is a Dockerfile parsed by the openschemas/extractors container.' |
| GITHUB_REPOSITORY | 'openschemas/extracors' | 
| IMAGE_DESCRIPTION | 'A Dockerfile build recipe' |


Note that if you are using the Github action associated with this repository, `GITHUB_REPOSITORY`
is defined for you (more on this in the next section).

## Github Action

This repository also serves an easy way to generate the file above and deploy
to Github pages! First, set up your `.github/main.workflow` in your repository 
to look like this:

```
workflow "Deploy ImageDefinition Schema" {
  on = "push"
  resolves = ["Extract ImageDefinition Schema"]
}

action "build" {
  uses = "actions/docker/cli@master"
  args = "build -t vanessa/salad ."
}

action "list" {
  needs = ["build"]
  uses = "actions/bin/sh@master"
  runs = "ls"
  args = ["/github/workspace"]
}

action "Extract ImageDefinition Schema" {
  needs = ["build", "list"]
  uses = "docker://openschemas/extractors:ImageDefinition"
  secrets = ["GITHUB_TOKEN"]
  env = {
    IMAGE_THUMBNAIL = "https://vsoch.github.io/datasets/assets/img/avocado.png"
    IMAGE_ABOUT = "Generate ascii art for a fork or spoon, along with a pun."
    IMAGE_DESCRIPTION = "alpine base with GoLang and PUNS."
  }
  args = ["extract", "--name", "vanessa/salad", "--contact", "@vsoch", "--filename", "/github/workspace/Dockerfile", "--deploy"]
}
```

 1. In the first block, we define the workflow, and say that it resolves with the last step.
 2. In the second block, we build our container from the Dockerfile at the root.
 3. In the third block, this is for debugging. You don't really need it, but it's a sanity check to list the workspace content.
 4. In the final block, we need to set environment variables that we want to change, and then run the container. Notice that I've changed the `--name` to be the container that we just build in the second step (vanessa/salar) and the `--contact` is also my name. The `--filename` needs to point to the Dockerfile in the Github workspace. The `--deploy` command will upload it to Github pages.

Note that we are using the same Docker container as above, but providing the 
entrypoint.sh a `GITHUB_TOKEN` via a secret (it's provided by Github),
along with customizations for the extraction in the environment. I'm also
putting my contact name (@vsoch) as a command line argument, and
running the command with `--deploy`. it will deploy the
static content back to Github pages. In summary, we have the following
variables:

| Variable | Default | 
|----------|---------|
| GITHUB_TOKEN | provided by Github in environemnt as secret |
| IMAGE_THUMBNAIL | 'https://vsoch.github.io/datasets/assets/img/avocado.png' |
| IMAGE_ABOUT | 'This is a Dockerfile parsed by the openschemas/extractors container.' |
| GITHUB_REPOSITORY | 'openschemas/extracors' (also provided by Github) | 
| IMAGE_DESCRIPTION | 'A Dockerfile build recipe' |
| GITHUB_ACTOR | Your Github username (provided by Github, you don't need to set) |
| GITHUB_REPO | The repository (again, provided by Github) |

When you deploy to Github pages for the first time, you
need to switch Github Pages to deploy from master and then back to the `gh-pages`
branch on deploy. There is a known issue with Permissions if you deploy
to the brain without activating it (as an admin) from the respository first.

Here is an example deployment in action! [vsoch/salad](https://github.com/vsoch/salad).
Specifically, see the [Github pages](https://vsoch.github.io/salad/). Note
that because we don't have any apt or pip packages, the softwareDependencies
is an empty list.

## Development

If you want to build the image locally, we follow the Docker Hub context rules
and the Dockerfile expects to be built from the [root of the repository](../).
This would then look like this:

```bash
$ docker build -f ImageDefinition/Dockerfile -t openschemas/extractors:ImageDefinition .
```
and if you want to push (because Docker Hub is slow sometimes)

```bash
$ docker push openschemas/extractors:ImageDefinition
```
