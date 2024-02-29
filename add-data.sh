#!/bin/bash

read -p "Enter the number of records to add: " num_records

# Generate a random application ID
application_id=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)

# Loop through each record
for i in $(seq 1 $num_records)
do
    # Generate random data for other fields
    applicant_name="ApplicantName$i"
    aadhaar_no="AADHAAR$i"
    gender="M"
    scheme_id=$((1 + RANDOM % 1000))
    state_board_id=$((1 + RANDOM % 1000))
    elastic_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Insert records into the tables with the same application_id
    psql -h localhost -U postgres -d nsp_fresh <<EOF
    INSERT INTO nspprod.data_applicant_registration_details (application_id, applicant_name, aadhaar_no, gender) 
    VALUES ('$application_id', '$applicant_name', '$aadhaar_no', '$gender');

    INSERT INTO payment.process_beneficary (application_id, applicant_name, aadhaar_no, gender) 
    VALUES ('$application_id', '$applicant_name', '$aadhaar_no', '$gender');

    INSERT INTO payment.in_merit_applicants (application_id, scheme_id, state_board_id, elastic_time) 
    VALUES ('$application_id', $scheme_id, $state_board_id, '$elastic_time');
EOF

done

echo "Records added successfully."

