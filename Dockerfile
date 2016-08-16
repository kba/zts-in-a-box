FROM node:argon

ENV NODE_ENV production

WORKDIR /app

COPY . /app

RUN npm --loglevel warn install

EXPOSE 1970

CMD npm start
# CMD npm run watch
