# Use the latest Ubuntu image
FROM ubuntu:22.04

# Install necessary packages for Terraform, OpenTofu, AWS CLI, Git, kubectl, Helm, and SSH
RUN apt-get update && \
    apt-get install -y wget unzip git curl apt-transport-https ca-certificates gnupg openssh-server sudo python3 python3-pip traceroute iputils-ping && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install tfenv
RUN git clone https://github.com/tfutils/tfenv.git /opt/tfenv && \
    ln -s /opt/tfenv/bin/* /usr/local/bin

# Install the latest Terraform version using tfenv
RUN tfenv install latest && \
    tfenv use latest

# Install tofuenv
RUN git clone https://github.com/tofuutils/tofuenv.git /opt/tofuenv && \
    ln -s /opt/tofuenv/bin/* /usr/local/bin

# Install the latest OpenTofu version using tofuenv
RUN tofuenv install 1.8.3 && \
    tofuenv use 1.8.3

# Detect CPU architecture and install the appropriate AWS CLI version
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else \
        echo "Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    curl "$AWS_CLI_URL" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -rf awscliv2.zip aws

# Install AWS Vault
RUN AWS_VAULT_VERSION=$(curl -s https://api.github.com/repos/99designs/aws-vault/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -L "https://github.com/99designs/aws-vault/releases/download/${AWS_VAULT_VERSION}/aws-vault-linux-amd64" -o /usr/local/bin/aws-vault && \
    chmod +x /usr/local/bin/aws-vault

# Install Boto3
RUN pip3 install boto3


# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /usr/share/keyrings/helm.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y helm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a new user 'iac-user' with sudo privileges
RUN useradd -m -s /bin/bash iac-user && echo 'iac-user:T0morrow' | chpasswd && adduser iac-user sudo

# Configure SSH to allow password authentication
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Start SSH service
RUN mkdir /var/run/sshd

# Expose SSH port
EXPOSE 22

# Ensure /usr/local/bin is in the PATH
ENV PATH="/usr/local/bin:${PATH}"

# Set the working directory
WORKDIR /home/iac-user

# Command to start SSH service
CMD ["/usr/sbin/sshd", "-D"]