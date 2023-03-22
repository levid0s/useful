gcloud auth print-access-token | out-file -encoding ASCII "$(git rev-parse --show-toplevel)/token.secret" -NoNewline  
