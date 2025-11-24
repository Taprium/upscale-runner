FROM --platform=$BUILDPLATFORM python:alpine

RUN apk update && apk add wget unzip

WORKDIR /src

# download models
RUN wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-ubuntu.zip && \
    unzip realesrgan-ncnn-vulkan-20220424-ubuntu.zip && rm realesrgan-ncnn-vulkan

ARG TARGETARCH

# Download realesrgan-vulkan-ncnn executable binaries
RUN if [ "$TARGETARCH" == "amd64" ]; then \
    wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-x64 -O realesrgan-ncnn-vulkan; \
    elif [ "$TARGETARCH" == "arm64" ]; then \
    wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-arm64 -O realesrgan-ncnn-vulkan; \
    elif [ "$TARGETARCH" == "arm" ]; then \
    wget https://github.com/Taprium/Real-ESRGAN-ncnn-vulkan-alpine/releases/download/v0.0.1/realesrgan-ncnn-vulkan-alpine-arm32 -O realesrgan-ncnn-vulkan; \
    fi

FROM --platform=$BUILDPLATFORM python:alpine

WORKDIR /app

RUN pip install pocketbase filelock

RUN apk update && apk add vulkan-loader libgomp libgcc
RUN cat /etc/apk/repositories

ARG TARGETARCH

RUN if [ "$TARGETARCH" == "amd64" ]; then \
    uname -m && apk update && apk search -eq '*-vulkan-*'| xargs apk add; \
    elif [ "$TARGETARCH" == "arm64" ]; then \
    apk add --no-cache --force-architecture --allow-untrusted mesa-vulkan-asahi; \
    elif [ "$TARGETARCH" == "arm" ]; then \
    uname -m && apk update && apk search -eq '*-vulkan-*'| xargs apk add; \
    fi

RUN rm -rf /var/cache/apk/*
COPY crontab.txt ./
COPY --from=0 /src/realesrgan-ncnn-vulkan ./
COPY --from=0 /src/models/* ./models/

RUN crontab crontab.txt && touch /var/log/taprium-upscale-runner.log

COPY *.py ./
COPY *.sh ./

RUN chmod +x /app/realesrgan-ncnn-vulkan 

CMD [ "bash", "entrypoint.sh"]
