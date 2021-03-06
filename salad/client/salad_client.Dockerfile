# build this image by cd'ing into this dir, and running
# docker build -f salad_client.Dockerfile -t enigma_salad_client .
# then run `docker-compose up` in the root project directory.

FROM node:10-buster as node_modules_build

COPY --from=gitclone_salad /root/salad/package.json /root/salad/package.json
COPY --from=gitclone_salad /root/salad/yarn.lock /root/salad/yarn.lock
COPY --from=gitclone_salad /root/salad/client/package.json /root/salad/client/package.json
COPY --from=gitclone_salad /root/salad/operator/package.json /root/salad/operator/package.json
WORKDIR /root/salad

# Build a custom enigma-js:
COPY --from=gitclone_contract /enigma-contract/ /root/enigma-contract/

# Build the smart contracts
RUN : \
    && cd /root/enigma-contract/ \
    && yarn \
    && yarn add truffle@5.1.2 \
    && npx truffle compile

# Build the enigma-js library
RUN : \
    && cd /root/enigma-contract/enigma-js \
    && yarn \
    && npx webpack --env build

# Install the local enigma-js library
RUN yarn workspaces run add 'file:/root/enigma-contract/enigma-js/'

# Install required dependencies + yarn and then clean the node_modules directory
RUN : \
    && yarn install --production \
    && yarn add truffle@5.1.2 mocha@6.2.2 --ignore-workspace-root-check \
    && npm install -g modclean \
    && modclean -n default:safe -r

##########################

FROM enigmampc/core-runtime-base:develop

ENV DEBIAN_FRONTEND noninteractive
ARG SGX_MODE=SW
ENV SGX_MODE $SGX_MODE
WORKDIR /root/salad

# Install curl, yarn, and node through APT
RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends yarn nodejs

# Install the python framework
COPY --from=enigma_common /root/wheels /root/wheels
COPY scripts/requirements.txt .
RUN pip3 install \
    --no-index \
    --find-links=/root/wheels \
    -r requirements.txt

COPY --from=gitclone_salad /root/salad /root/salad
COPY --from=gitclone_salad /root/salad/client /root/salad/client
COPY --from=gitclone_salad /root/salad/smart_contracts /root/salad/smart_contracts
COPY --from=gitclone_salad /root/salad/package.json /root/salad/
COPY --from=gitclone_salad /root/salad/truffle.js /root/salad/
RUN true
COPY --from=node_modules_build /root/salad/node_modules /root/salad/node_modules
RUN true
COPY --from=node_modules_build /root/salad/client/node_modules /root/salad/client/node_modules

# Set up the environment variable defaults and compile the smart contracts
RUN : \
    && cp '.env.template' '.env'\
    && npx truffle compile

COPY scripts ./scripts/
COPY config ./config/

ENTRYPOINT ./scripts/run.sh
