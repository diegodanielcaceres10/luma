FROM julesreyn/flutter-android-sdk:jdk17-android33-flutter3.24.3

WORKDIR /app

ENV PUB_CACHE=/root/.pub-cache
ENV GRADLE_USER_HOME=/root/.gradle

RUN flutter config --no-analytics

CMD ["flutter", "build", "apk", "--split-per-abi"]