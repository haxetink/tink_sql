const mysql = require('mysql')
const fs = require('fs')
const connection = mysql.createConnection({
  user: 'root',
  multipleStatements: true
})
connection.query(fs.readFileSync(process.argv[2], 'utf8'), function (err) {
  connection.end()
  if (!err) return
  console.error(err)
  process.exit(1)
})