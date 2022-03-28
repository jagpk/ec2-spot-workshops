FROM klakegg/hugo:0.64.1-ext-asciidoctor AS build

COPY . /src
RUN mkdir /var/www/ \
 && hugo build --cleanDestinationDir --verbose \
 && cp -r /target/* /var/www/
RUN cd /var/www \
 && tar cf /var/www.tar *

FROM ubuntu
RUN apt-get update \
 && apt-get install nginx -y
EXPOSE 80
COPY --from=build /var/www /var/www/html
CMD ["nginx","-g","daemon off;"]
