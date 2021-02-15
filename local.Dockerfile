ARG METADATASERVICE_BASE
ARG SEARCHSERVICE_BASE

FROM node:12-slim as node-stage
WORKDIR /app/amundsen_application/static

COPY amundsen_application/static/package.json /app/amundsen_application/static/package.json
COPY amundsen_application/static/package-lock.json /app/amundsen_application/static/package-lock.json
RUN npm install

COPY amundsen_application/static/ /app/amundsen_application/static/
RUN npm rebuild node-sass
RUN npm run dev-build

COPY . /app

FROM python:3.7-slim
WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip3 install -r requirements.txt

COPY --from=node-stage /app /app

RUN python3 setup.py install


# Additional steps in node-stage to get custom static conf files
RUN apt-get update && apt-get install -y rsync npm
ADD frontend /app/frontend/
WORKDIR /app/frontend/
RUN ln -s ../ upstream
RUN chmod 755 partnerized-static-build.sh
RUN ./partnerized-static-build.sh

# ENTRYPOINT [ "python3" ]
# instead of CMD [ "python3",  "amundsen_application/wsgi.py" ] 
CMD [ "python3",  "frontend/upstream/amundsen_application/wsgi.py" ] 

