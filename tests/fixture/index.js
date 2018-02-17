const mysql = require('mysql')
const fs = require('fs')
function env(key, byDefault) {
  return process.env[key] || byDefault
}
const connection = mysql.createConnection({
  user: env('DB_USERNAME', 'root'),
  password: env('DB_PASSWORD', ''),
  multipleStatements: true
})
connection.query(fs.readFileSync(process.argv[2], 'utf8'), function (err) {
  connection.end()
  if (!err) return
  console.error(err)
  process.exit(1)
})