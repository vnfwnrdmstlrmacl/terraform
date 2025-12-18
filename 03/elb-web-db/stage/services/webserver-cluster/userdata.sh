#!/bin/bash

dnf install -y httpd
cat <<EOF > /var/www/html/index.html
<h1>db ip : ${dbaddress}</h1>
<h1>db port : ${dbport}</h1>
<h1>db name : ${dbname}</h1>
EOF
systemctl enable --now httpd