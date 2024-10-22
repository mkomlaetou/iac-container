# before building image under iac-user password on line 63 from default password "T0morrow" to any

# build image
docker-compose build

# start container
docker-compose up -d

# ssh into container, default password "T0morrow"
ssh iac-user@localhost -p 2266