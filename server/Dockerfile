FROM oven/bun:latest

RUN apt-get update
RUN apt-get install -y python3 ffmpeg

COPY bun.lock .
COPY package.json .

RUN bun install --frozen-lockfile

COPY . .
RUN rm -rf files/

EXPOSE 3000
CMD ["bun", "index.ts"]