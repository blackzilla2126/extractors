#!/bin/bash

usage () {

    echo "Usage:


         docker run <container> [help|extract]

         Commands:

                help: show help and exit
                extract: extract a json-ld or html page for a specific schema.org
                         data type (ImageDefinition), from a Dockerfile
         
         Options [extract]:

                --contact | -c the name to add as the maintainer / contact
                --name|-n:     the name of the container for the Dockerfile
                -f|--filename: specify a Dockerfile path (other than Dockerfile)
                --html         output html instead
                --deploy       if running in a Github action, given that
                               GITHUB_TOKEN is also defined, deploy html
                               page with embedded json-ld back to Github Pages

         Examples:

              docker run <container> extract --contact vsoch
              docker run <container> extract --contact vsoch --html
              docker run <container> extract --contact vsoch -f /path/to/Dockerfile

         "
}

if [ $# -eq 0 ]; then
    usage
    exit
fi

EXTRACTION="no"
DOCKERFILE="Dockerfile"
OUTPUT_FORMAT="json"
CONTAINER_NAME=""
DEPLOY="no"
HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

while true; do
    case ${1:-} in
        -h|--help|help)
            usage
            exit
        ;;
        --extract|extract|-e)
            shift
            EXTRACTION="yes"
        ;;
        --filename|-f)
            shift
            DOCKERFILE="${1:-}"
            shift
        ;;
        --contact|-c)
            shift
            MAINTAINER="${1:-}"
            shift
        ;;
        --html|html)
            shift
            OUTPUT_FORMAT="html"
        ;;
        --deploy)
            shift
            DEPLOY="yes"
        ;;
        --name|-n)
            shift
            CONTAINER_NAME="${1:-}"
            shift
        ;;
        -*)
            echo "Unknown option: ${1:-}"
            exit 1
        ;;
        *)
            break
        ;;
    esac
done

# Deploy requires GITHUB_TOKEN
if [ -z "${GITHUB_TOKEN}" ]; then
    DEPLOY="no"
fi

if [ -z "${MAINTAINER}" ]; then
    echo "Please provide a --contact for the contact."
    exit 1;
fi

# Are we doing an extraction?

if [ "${EXTRACTION}" == "yes" ]; then

    echo "Preparing to do extraction."
    echo "Dockerfile: ${DOCKERFILE}"
    echo "Container Name: ${CONTAINER_NAME}"
    echo "Output Format: ${OUTPUT_FORMAT}"

    # Does the Dockerfile exist?
    if [ ! -f "${DOCKERFILE}" ]; then
        echo "${DOCKERFILE} does not exist.";
        exit 1;
    fi

    # If we are deploying, then pipe into a file
    if [ "${DEPLOY}" == "yes" ]; then

        # Write the index file
        python3 ${HERE}/run.py "${DOCKERFILE}" "html" "${MAINTAINER}" "${CONTAINER_NAME}" > /opt/index.html
        cat /opt/index.html

        # We know that GITHUB_TOKEN is in environment from check above
        /bin/bash ${HERE}/deploy.sh /opt/index.html

    # Otherwise just do the extraction
    else
        python3 run.py "${DOCKERFILE}" "${OUTPUT_FORMAT}" "${MAINTAINER}" "${CONTAINER_NAME}"
    fi

else
    echo "Please select an action (e.g., docker run <container> extract <options>)"
fi
