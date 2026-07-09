const url = 'https://eaihqwzhfwtwzqmsrkgk.supabase.co/auth/v1/token?grant_type=password';
const apiKey = 'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5';

fetch(url, {
  method: 'POST',
  headers: {
    'apikey': apiKey,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: 'nguyenbaotruong160@gmail.com',
    password: '0813872387'
  })
}).then(res => res.json()).then(authData => {
  if (authData.error) {
    console.log('Login Error:', authData);
    return;
  }
  
  console.log('Login Success! UID:', authData.user.id);
  
  const token = authData.access_token;
  
  // Now try to fetch from users table
  const dbUrl = `https://eaihqwzhfwtwzqmsrkgk.supabase.co/rest/v1/users?select=*&iduser=eq.${authData.user.id}`;
  
  fetch(dbUrl, {
    headers: {
      'apikey': apiKey,
      'Authorization': `Bearer ${token}`
    }
  }).then(res => res.json()).then(dbData => {
    console.log('DB Query Result:', dbData);
  });
});
