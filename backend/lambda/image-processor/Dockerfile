FROM public.ecr.aws/lambda/python:3.11

# Install system dependencies for Pillow
RUN yum install -y \
    libjpeg-devel \
    zlib-devel \
    libwebp-devel \
    && yum clean all

# Copy requirements and install dependencies
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

# Copy function code
COPY handler.py ${LAMBDA_TASK_ROOT}/

# Set the CMD to handler
CMD ["handler.handler"]
