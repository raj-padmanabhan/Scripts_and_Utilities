try:
    from urllib.request import Request, urlopen, URLError
    from urllib.parse import urlencode
except:
    from urllib2 import Request, urlopen, URLError
    from urllib import urlencode
    input = raw_input
import json, ssl, os, socket, sys
import datetime, getpass, argparse

# Defines the entry point into the script
def main(argv):

    currentHost = socket.getfqdn().lower()
    portalHost = ''
    adminUsername = ''
    adminPassword = ''
    token = ''

    # Prompt for server hostname 
    portalHost = input('Enter Portal for ArcGIS hostname [{}]: '.format(currentHost))
    if portalHost == '':
        portalHost = currentHost
    portalHost = checkHost(portalHost)

    # Prompt for admin username
    adminUsername = input('Enter administrator username: ')
    while adminUsername == '':
        adminUsername = input('Administrator username is required. Enter administrator username: ')

    # Prompt for admin password 
    adminPassword = getpass.getpass(prompt='Enter administrator password: ')
    while adminPassword == '':
        adminPassword = getpass.getpass(prompt='Administrator password is required. Enter administrator password: ')
        

    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        # Legacy Python that doesn't verify HTTPS certificates by default
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context

    portalUrl = 'https://' + portalHost + ':7443/arcgis'

    if token == '':
        token,portalUrl = generateToken(adminUsername,adminPassword,portalHost,portalUrl)
    portalVer = checkToken(portalUrl,token)
    enableCanSignInArcGIS(portalUrl,token)



 
# Function to check hostname resolution and confirm Portal is running
def checkHost(hostname):
    try:
        socket.getaddrinfo(hostname, None)
    except:
        print('Unable to resolve hostname - {}'.format(hostname))
        sys.exit(1)
    if '.' not in hostname:
        hostname = socket.getfqdn(hostname)
    if not isOpen(hostname, 7443):
        print('Unable to access Portal for ArcGIS on {} over port 7443'.format(hostname))
        sys.exit(1)
    return hostname

# Enable canSignInArcGIS property
def enableCanSignInArcGIS(portalUrl,token):

    params = {'referer':'canSignInArcGIS',
              'f':'json'}

    try:
        request = Request(portalUrl + '/sharing/rest/portals/self')
        request.add_header('X-Esri-Authorization', 'Bearer ' + token)
        response = urlopen(request, urlencode(params).encode())
        portalSelf = json.loads(toString(response.read()))
        if 'error' in portalSelf:
            print('Error checking Portal properties\n{}'.format(portalSelf.get('error')))
        else:
            if 'canSignInArcGIS' in portalSelf:
                if portalSelf.get('canSignInArcGIS'):
                    print('\nError: ArcGIS logins are already enabled.')
                else:
                    print('\nEnabling ArcGIS logins...')
                    request = Request(portalUrl + '/sharing/rest/portals/0123456789ABCDEF/update')
                    request.add_header('X-Esri-Authorization', 'Bearer ' + token)
                    params = {'referer':'canSignInArcGIS',
                            'f':'json',
                            'canSigninArcGIS':'true'}
                    response = urlopen(request, urlencode(params).encode())

                    canSignInResult = json.loads(toString(response.read()))
                    request = Request(portalUrl + '/sharing/rest/portals/self')
                    request.add_header('X-Esri-Authorization', 'Bearer ' + token)
                    response = urlopen(request, urlencode(params).encode())
                    portalSelf = json.loads(toString(response.read()))
                    if 'canSignInArcGIS' in portalSelf:
                        if portalSelf.get('canSignInArcGIS'):
                            print('Success: ArcGIS logins have been enabled.')
                        else:
                            print('Error: Could not enable ArcGIS logins.')

    except Exception as e:
        print('Error checking Portal properties\n{}'.format(e))



# Function to generate token
def generateToken(username,password,portalHost,portalUrl):
    tokenUrl = portalUrl + '/sharing/rest/generateToken'
    params = {'username':username,
              'password':password,
              'referer':'canSignInArcGIS',
              'f':'json'}
    try:
        request = Request(tokenUrl, urlencode(params).encode())
        response = urlopen(request)
        if response.url != tokenUrl:
            portalUrl = 'https://' + response.url.lower().split('/')[2] + '/arcgis'
            testSSL(portalUrl + '/sharing/rest/?f=json')
            tokenUrl = portalUrl + '/sharing/rest/generateToken'
            request = Request(tokenUrl, urlencode(params).encode())
            response = urlopen(request)
        genToken = json.loads(toString(response.read()))
        if 'token' in genToken.keys():
            return genToken['token'], portalUrl
        else:
            print('\nInvalid administrator username or password\n{}'.format(genToken))
            sys.exit(1)
    except Exception as e:
        print('Unable to access Portal for ArcGIS on {}:7443\n{}'.format(portalHost, e))
        sys.exit(1)

# Function to check the portal token and return the portal version if valid
def checkToken(portalUrl,token):
    try:
        request = Request(portalUrl + '/portaladmin/?token=' + token + '&f=json')
        request.add_header('Referer', 'canSignInArcGIS')
        response = urlopen(request)
        adminInfo = json.loads(toString(response.read()))
        if 'version' in adminInfo.keys():
            return str(adminInfo['version'])
        else:
            print('\nThe user or token provided does not have administrative privileges\n{}'.format(adminInfo))
            sys.exit(1)
    except Exception as e:
        print('\nError validating token\n{}'.format(e))
        sys.exit(1)


def toString(data):
    try:
        return data.decode('utf-8')
    except:
        return data

def isOpen(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.settimeout(2)
        s.connect((ip, int(port)))
        s.close()
        return True
    except:
        return False

# Script start
if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except:
        sys.exit(1)