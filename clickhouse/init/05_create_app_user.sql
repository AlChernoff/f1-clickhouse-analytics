CREATE USER IF NOT EXISTS f1_app
IDENTIFIED WITH plaintext_password BY 'f1_app_password';

GRANT ALL ON raw.* TO f1_app;
GRANT ALL ON dwh.* TO f1_app;
GRANT ALL ON marts.* TO f1_app;
GRANT ALL ON monitoring.* TO f1_app;
GRANT SELECT ON system.* TO f1_app;
