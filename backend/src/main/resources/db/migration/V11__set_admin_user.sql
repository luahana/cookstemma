-- Set admin role for truepark0@gmail.com (fix for V9 which may have run before user existed)
UPDATE users SET role = 'ADMIN' WHERE email = 'truepark0@gmail.com';
