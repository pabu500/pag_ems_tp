# Stage 1 - Install dependencies and build the app
FROM ubuntu:22.04 AS builder

RUN apt-get update
RUN apt-get install -y bash curl file git unzip xz-utils zip libglu1-mesa
RUN apt-get clean

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN apt-add-repository ppa:git-core/ppa
RUN apt-get install -y git

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
# RUN /usr/local/flutter/bin/flutter doctor -v
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Change stable channel
RUN flutter channel stable

# Enable web capabilities
RUN flutter config --enable-web
RUN flutter upgrade
RUN flutter pub global activate webdev

# RUN flutter --version

# RUN flutter doctor -v

# Copy files to container and build
RUN mkdir /app
COPY . /app
WORKDIR /app

# making sure we get the latest version of the dependencies
COPY pubspec.yaml pubspec.yaml
#COPY pubspec.lock pubspec.lock
RUN rm -f pubspec.lock
RUN rm -rf /root/.pub-cache

RUN flutter pub get
RUN flutter build web --no-tree-shake-icons

# Stage 2 - Create the run-time image
#FROM nginx:stable-alpine AS runner
#FROM nginx:1.21.1-alpine
FROM nginx:stable-alpine

# COPY default.conf /etc/nginx/conf.d
COPY ./nginx/default.conf /etc/nginx/conf.d
# COPY package.json /usr/share/nginx/html
COPY --from=builder /app/build/web /usr/share/nginx/html