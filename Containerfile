ARG PYTHON_VERSION=3.10.6
ARG POETRY_VERSION=1.2.0
ARG NODE_VERSION=18.8.0

# NODEJS BUILDER
FROM docker.io/library/node:${NODE_VERSION} as js_builder
ENV NODE_ENV=production
WORKDIR /web
COPY ./web .
RUN npm ci
RUN npm run build

# PYTHON BUILDER
FROM docker.io/library/python:${PYTHON_VERSION} as py_builder
ENV DEBIAN_FRONTEND=noninteractive \
  ## poetry
  ## https://python-poetry.org/docs/configuration/#using-environment-variables
  POETRY_VERSION=${POETRY_VERSION} \
  POETRY_HOME=/opt/poetry \
  POETRY_VIRTUALENVS_CREATE=true \
  POETRY_VIRTUALENVS_IN_PROJECT=true \
  POETRY_VIRTUALENVS_OPTIONS_NO_PIP=true \
  POETRY_VIRTUALENVS_OPTIONS_NO_SETUPTOOLS=true \
  POETRY_NO_INTERACTION=1 \
  ## rust
  CARGO_HOME=/opt/cargo \
  RUSTUP_HOME=/opt/rustup
ENV PATH=$POETRY_HOME/bin:$CARGO_HOME/bin:$PATH
RUN curl -sSL https://install.python-poetry.org | python3 - -y
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -yq
## PYTHON DEPENDENCIES
WORKDIR /app
COPY poetry.lock pyproject.toml .
RUN poetry install --only main

# RUNTIME
FROM docker.io/library/python:${PYTHON_VERSION}-slim as runtime
ENV PATH=/app/.venv/bin:$PATH \
  PYTHONPATH=/app:$PYTHONPATH \
  PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1 \
  PORT=8000
EXPOSE $PORT
ENTRYPOINT ["python"]
CMD ["-m", "rmp"]
## APP
COPY --from=js_builder /web/public /public
COPY --from=py_builder /app /app
COPY . /app
