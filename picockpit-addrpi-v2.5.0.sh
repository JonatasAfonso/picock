#!/usr/bin/env bash

# IMPORTANT SECURITY ADVICE: never execute scripts without first checking what they do!!
# you're doing good by looking at this :-)
#
# This scripts serves the function of installing the Picockpit-Client.
# It checks for the installed release of Raspberry Pi OS, 
# older installs of picockpit-client and acts accordingly.
# We obtain an API key using the one time key (OTK) which was generated by the PiCockpit frontend for you.

readonly OTK="bqTcg4i.3MbjH2kGSzLV4houvPdKwrnkXPBJmTby4"
readonly PI_NAME="PiHole"

# installing curl and jq for http request and json parsing
sudo apt-get update && sudo apt-get --yes install curl jq

# We check whether we should install the version that is intended for Buster.
if [ "$(lsb_release -cs)" == 'buster' ]; then
		curl -L http://repository.picockpit.com/picockpit.public.key | sudo apt-key add -

		# We check if the repository already exists, if not we add it.
		grep -qsxF 'deb http://repository.picockpit.com/raspbian buster main' /etc/apt/sources.list.d/picockpit.list || echo "deb http://repository.picockpit.com/raspbian buster main" | sudo tee --append /etc/apt/sources.list.d/picockpit.list > /dev/null
		# After making sure the repository exists we simply update and install with apt-get.
		sudo apt-get update
		sudo apt-get install picockpit-client

# If the system isn't based on Buster we check whether Bullseye is used.
elif [ "$(lsb_release -cs)" == 'bullseye' ]; then
  #wget -O- -q http://repository.picockpit.com/picockpit.public.key | gpg --dearmor | sudo tee /usr/share/keyrings/picockpit-archive-keyring.gpg >/dev/null
  curl -L http://repository.picockpit.com/picockpit.public.key | sudo apt-key add -

  # We need to check whether there already a repository of the version intended for use on buster was added beforehand. This would lead to some problems. If that is the case, we need to clean up a bit. 
  if grep -qsxF 'deb http://repository.picockpit.com/raspbian buster main' /etc/apt/sources.list.d/picockpit.list; then 

    # Since there exists an old repository it is reasonable to assume that there might also be a old version installed. Let us check and delete if necessary.
    if [ "$(dpkg-query -W -f='${db:Status-Abbrev}' picockpit-client)" == 'ii' ]; then 
      sudo apt-get -y remove picockpit-client
    fi

    # We replace the old repository with the new one for Bullseye.
    echo "deb http://repository.picockpit.com/raspbian bullseye main" | sudo tee /etc/apt/sources.list.d/picockpit.list > /dev/null
    sudo apt-get update
    sudo apt-get install picockpit-client

		# This should be the regular case for a bullseye install. Either the repository for Bullseye already exists or we add it. Afterwards we install picockpit.
    else 
      grep -qsxF 'deb http://repository.picockpit.com/raspbian bullseye main' /etc/apt/sources.list.d/picockpit.list || echo "deb http://repository.picockpit.com/raspbian bullseye main" | sudo tee --append /etc/apt/sources.list.d/picockpit.list > /dev/null
      sudo apt-get update
      sudo apt-get install picockpit-client
    fi

else
	echo 'There is a problem with reading the installed version via lsb_release. This installation script is intended for Raspberry Pi OS based either on Buster or Bullseye.'
  exit 1
fi

if dpkg -l "picockpit-client"; then
  echo "picockpit-client is installed"
else
  echo "picockpit-client was not installed successfully"
  exit 1
fi


# get new API key
echo "Requesting new API key........"
# response=$(curl --insecure --silent -X POST "https://picockpit.local/api/v2.0/otk/newapikey" -H "Content-Type: application/json" --data-binary @- <<DATA
response=$(curl --silent -X POST "https://picockpit.com/api/v2.0/otk/newapikey" -H "Content-Type: application/json" --data-binary @- <<DATA
{
  "otk": "${OTK}",
  "piName": "${PI_NAME}"
}
DATA
)
echo "response: ${response}"

success=$(jq -r '.success' <<<"${response}")
if [[ $success == true ]]; then
	api_key=$(jq -r '.apikey' <<<"${response}")
	echo "Getting your API-key was successful."
	echo "API Key: ${api_key}"
else
	echo "There was a problem generating the API Key. Please try generating your API-key manually in PiCockpit."
	exit 1
fi


# Check if given name for the device has dashes at the beginning
if [[ "${PI_NAME}" =~ ^-+S* ]]; then
  echo "${PI_NAME} is not a valid name"
  echo "remove the dashes at the beginning of your name"
  exit 1
fi

# as a last step we call the connect function of the picockpit-client.
# the --yes skips some general questions for a smoother experience.
echo "starting picockpit-client and connecting your Raspberry Pi as '${PI_NAME}' with the following API key: '${api_key}'"
sudo picockpit-client connect --yes --apikey "${api_key}" --name "${PI_NAME}"

read -p "Press Enter to continue"

# author: pi3g e.K.
# copyright 2022

# IN NO EVENT WILL pi3g e.K. BE LIABLE FOR ANY INDIRECT, PUNITIVE, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES,
# INCLUDING WITHOUT LIMITATION DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA OR OTHER INTANGIBLE LOSSES,
# ARISING UNDER OR RELATING TO THIS AGREEMENT OR FROM THE USE OF, OR INABILITY TO USE, THE SERVICE.

# when in doubt do not use this software and service. Simples.
