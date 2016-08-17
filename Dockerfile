FROM node:argon

ENV NODE_ENV production

WORKDIR /app

EXPOSE 1970

COPY . /app

RUN npm --loglevel warn install

CMD npm start
