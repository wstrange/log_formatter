FROM dart:stable as build

WORKDIR /app

ADD pubspec.* /app/
RUN dart pub get
COPY . .

RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

CMD ["/app/bin/server"]