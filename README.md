# Hikvision DVR/NVR bruteforce

Bash script for ethical security testing of Hikvision IP Cameras, aimed at identifying vulnerabilities to brute-force attacks

## Synopsis

Some Hikvision DVR/NVR systems employ an insecure authentication mechanism in their web interface, allowing attackers to send repeated authentication requests until a match is found.

The conclusions presented here are the result of independent research. Further investigation revealed a disclosure notice on [Seclists.org](https://seclists.org/fulldisclosure/2017/Sep/23) (ICSA-17-124-01), highlighting a more severe vulnerability employing a similar approach. Sending a crafted request to the exposed URI endpoints with the string `YWRtaW46MTEK`(which decodes to `admin:11`) enables unauthenticated impersonation of any configured user account.


**It is strongly advised to test your system against this vulnerability before proceeding with the brute-force script.**

Example of vulnerable web interface:

![web_interface](https://github.com/EarlyOwl/HTTeaPot/assets/49495410/31e3d9c2-b2b7-44ed-b314-ce0e8acbcf0e)

## Points of attention

- According to the [documentation](https://www.hikvision.com/content/dam/hikvision/ca/bulletin/technical-bulletin/other/dvrnvr_web_component_qsg.pdf), default credentials are used (admin/12345)
- Authentication details are sent without encryption via an HTTP GET request using request headers.
- The **admin** user is enabled by default
- The string used in the "Authorization" header combines the username and password, encoded in Base64 (for more details, see [Vulnerability details](#vulnerability-details))
- There appears to be no rate limit on failed login attempts.

## Vulnerability details
When credentials are entered on the login page, a string is created using the format `username:password` and sent in the HTTP "Authorization" header in Base64 encoding.
For example, given the input username = `admin` and password = `123456`, the resulting string would be `admin:123456`, and `YWRtaW46MTIzNDU2` after Base64 encoding.

This Base64 string is then sent in the "Authorization" header in the format `Authorization: Basic YWRtaW46MTIzNDU2` via a GET request to `http://x.x.x.x/PSIA/Custom/SelfExt/userCheck`. When incorrect credentials are provided, the response (which still has a status of 200 OK) contains the following lines:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<userCheck>
<statusValue>401</statusValue>
<statusString>Unauthorized</statusString>
</userCheck>
```

Since there are no rate limits on failed login attempts, it is possible to send a vast number of GET requests until the correct password is found.

## Mitigation
**If your system is exposed, take action now!**
Access to the web interface should only be allowed from trusted sources, and direct exposure to the internet MUST be avoided.
Failing to do so will result in a security breach. Be aware that many ISP-grade routers have UPnP enabled by default, which could unknowingly expose port 80/TCP.

## Legal notice
By using this code, you hereby agree to the license details, with particular attention to the following points:

2. The code provided under this license is intended for use on owned systems only. By using this code, you agree to do so in compliance with all applicable local laws and regulations.
3. The author of this code prohibits any illicit or unlawful use of the code, including but not limited to unauthorized access, data breaches, or any other illegal activities. Users are solely responsible for ensuring that their use of the code complies with all applicable laws and regulations.
4. The author of this code shall not be held responsible for any damages or liabilities arising from the use of the code, including but not limited to any security vulnerabilities or breaches.

## Installation
1. Download hikvision-bruteforce.sh from the main branch of this repo to your local machine:
```shell
wget https://raw.githubusercontent.com/EarlyOwl/Hikvision-DVR-NVR-bruteforce/main/hikvision-bruteforce.sh
```

2. Make it executable
```shell
chmod +x hikvision-bruteforce.sh
```

3. Run the script (see [usage](#usage)).

## Usage
```shell
./hikvision-bruteforce.sh [-u USERNAME] [-i IP] [-f FILE_PATH]
```

Where (*all parameters are optional*):
- `-u`: specify the username to use in login attempts. Default is *admin*.
- `-i`: specify the ip address of the system. Default is *192.168.0.64*.
- `-f`: specify the password list file. Default is *password_list.txt*

Please note that:
- Passwords MUST be one per line.
- No password list will be provided in this repo.

Example usage:
```shell
./hikvision-bruteforce.sh -u admin -i 192.168.0.64 -f passwords.txt
```

The script initially tries to connect to the login page to verify the system's accessibility.
Then, it iterates through each password in the list, stopping upon finding a successful match