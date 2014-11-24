#!/usr/bin/env ruby
require 'mysql2'

client = Mysql2::Client.new(host: '10.38.1.43', username: 'appserver', password: 'appserverpass')
results = client.query("select table_name, column_name from information_schema.columns where extra = 'auto_increment' and table_schema = 'weddingwire' order by table_name, column_name")
File.open('/Users/asurin/regenerate_auto_increment.sql', 'w') do |out|
  out.write "use weddingwire;\r\n"
  out.write <<-eos
  /*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
  /*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
  /*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
  /*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
eos
  results.each_with_index do |row, index|
    puts index
    max_value_result = client.query("SELECT max(#{row['column_name']}) as m_val from weddingwire.#{row['table_name']}").first
    max_value = (max_value_result['m_val'] || 0) +1
    out.write <<-eos
    begin;
    insert into #{row['table_name']} (#{row['column_name']}) values (#{max_value});
    delete from #{row['table_name']} where #{row['column_name']} = #{max_value};
    commit;
eos
  end
  out.write <<-eos
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
eos
end