#!/bin/bash

echo "Hello! This is a placeholder for init commands during the devcontainer launch process."

# Performing this action is a script avoids creating a literal '{.aws,.ssh}' directory.
mkdir -p ~/{.aws,.ssh}
