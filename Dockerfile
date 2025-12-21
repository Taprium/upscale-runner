FROM alpine:latest AS prep

RUN apk add --no-cache wget unzip 

WORKDIR /realesrgan
# download models
RUN wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-ubuntu.zip && \
    unzip realesrgan-ncnn-vulkan-20220424-ubuntu.zip && rm *.mp4 *.jpg realesrgan*

ARG TARGETARCH

# Download realesrgan-vulkan-ncnn executable binaries
RUN if [ "$TARGETARCH" == "amd64" ]; then \
        wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-x64 -O realesrgan-ncnn-vulkan; \
    elif [ "$TARGETARCH" == "arm64" ]; then \
        wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-arm64 -O realesrgan-ncnn-vulkan; \
    fi
    
# elif [ "$TARGETARCH" == "armv7" ]; then \
#     wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-armv7 -O realesrgan-ncnn-vulkan; \
# elif [ "$TARGETARCH" == "armv6" ]; then \
#     wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-armv6 -O realesrgan-ncnn-vulkan; \
# fi

# Compile dart code
WORKDIR /src

RUN apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing dart-sdk
COPY . .

RUN touch .env && \
    dart run build_runner build --delete-conflicting-outputs &&\
    dart compile exe bin/taprium_upscale_runner.dart -o bin/taprium-upscale-runner

FROM alpine:latest

WORKDIR /app

RUN apk update && \
    apk add --no-cache vulkan-loader libgomp libgcc icu-libs && \
    apk search -eq 'mesa-vulkan-*' | grep -v 'layers' | xargs apk add --no-cache &&\
    rm -rf /var/cache/apk/*

COPY crontab.txt *.py *.sh ./
COPY --from=prep /src/bin/taprium-upscale-runner ./
COPY --from=prep /realesrgan/realesrgan-ncnn-vulkan ./
COPY --from=prep /realesrgan/models/* ./models/

RUN crontab crontab.txt && touch /var/log/taprium-upscale-runner.log && rm crontab.txt && chmod +x /app/realesrgan-ncnn-vulkan && chmod +x /app/taprium-upscale-runner

CMD [ "sh", "entrypoint.sh"]
