to use app with emulator: 

1. activate dev mode on your android phone
2. connect phone to laptop via USB
3. connect laptop and phone to same wifi
4. get your IP4 address by opening a terminal and running ipconfig 
5. open the project folder in your VS Code editor 
6. change IP address in main.dart (2 places) to your IP4 address
7. change the IP address in seed.js (2 places) to your IP4 address
8. add the IP4 address to: android/app/src/main/res/xml/network_security_config.xml 
    - e.g. 
    <?xml version="1.0" encoding="utf-8"?>
    <network-security-config>
        <domain-config cleartextTrafficPermitted="true">
            <domain includeSubdomains="true">192.168.1.153</domain>
            <domain includeSubdomains="true">10.0.2.2</domain>
            <domain includeSubdomains="true">172.20.10.2</domain>
            <domain includeSubdomains="true">172.29.2.191</domain>
            <domain includeSubdomains="true">192.168.12.222</domain>
        </domain-config>
    </network-security-config> 
9. start the emulator by running ./start in the terminal
10. the app should now be ready to run


When you close the emulator it automatically saves the current data to the project source. 
To delete the current emulator data, find and delete the entire emulator data file in the project source.
New data will be seeded to the emulator when you restart it.


To ensure profiles load in to your app, they will need to be within range of your current location. 
Find your latitude and longitude coordinates and change the ones found in the seed.js file. 
They will be in the seedData() function:
    const centerLat = YOUR_LATITUDE;
    const centerLon = YOUR_LONGITUDE;


There are many bugs still as seen in notes.txt


If you tried this and it does not work let me know:

- X: @elijah_m_2
- email: elijahmedrano567@gmail.com