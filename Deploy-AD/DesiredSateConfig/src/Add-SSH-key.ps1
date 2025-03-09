

configuration Add-Key {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds

    ) 
    Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xPSDesiredStateConfiguration, ComputerManagementDsc
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** Install ADCS *****
        xScript InstallADCS
        {
            SetScript = {
                New-Item -ItemType Directory -Path "C:\ProgramData\DOAZLab" -Force > $null
                $targetPath = "C:\ProgramData\DOAZLab\id_rsa"

                $privateKey = @"
                -----BEGIN OPENSSH PRIVATE KEY-----
                b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
                NhAAAAAwEAAQAAAgEAtV8aFw/6ByVPYXCXOBr9PtWSl2a3eHsqKmxtEVTAcF38pXOOToyO
                KELMCtLEBrYc8PpI1GW/dHXJDyDpdBhT2QrBLyJ57wSWgo7EucCrKu26IZ0SVD/HA11zoe
                MqwknDLwXfKNcSmz0L2q3/pEq26eKRd7HYasD43zDqtH471DLqa344llcTgpgnn4cjrVIL
                0YRREEkm7TzekjLT6oESprV8LDDcFFlrziV36zkJeViUaA3Lx7M/TZUdjVy3gbwGcP152H
                lMgr9kMJeU2hZOvy9bsbIQILdZ/OhzqCQ5wHXF4nhwNx6+ogGPmIVuUyFjeDjKdTKSVBwQ
                g+u5/ADQWubYAcoXGnzTD6hxYhNm6P8xBys/Z05IzSJgobv9J+IQFo63yYKKEwvaC2tWcr
                rxi53mHLjWrGQZAcNueZdABYK2Xs+61qiw4cgsW+E9Rx8HI9BknKcrbQBQBCjU0VX8tw7D
                RWlpL8KGtWtDIIXL8/w9O4y+L6luoHL4L0OmmAAQhTTKxftzxZwM/y1B+3dJ7aZVyJzNqW
                ZqhyOHWnGFIH9WySPmlBZE+l/cHmWXcFaA8nyvJtiqd1pGa96/KCs+uX8PKtp1LZrgg4Dn
                1MDi/DzcJd6KybCZ/ZA1Xmypm6HT+01CCxyeHrW0mqCK5XJmjvijG3Y3V/oSdm9+EpCDKV
                0AAAdIvPR2+Lz0dvgAAAAHc3NoLXJzYQAAAgEAtV8aFw/6ByVPYXCXOBr9PtWSl2a3eHsq
                KmxtEVTAcF38pXOOToyOKELMCtLEBrYc8PpI1GW/dHXJDyDpdBhT2QrBLyJ57wSWgo7Euc
                CrKu26IZ0SVD/HA11zoeMqwknDLwXfKNcSmz0L2q3/pEq26eKRd7HYasD43zDqtH471DLq
                a344llcTgpgnn4cjrVIL0YRREEkm7TzekjLT6oESprV8LDDcFFlrziV36zkJeViUaA3Lx7
                M/TZUdjVy3gbwGcP152HlMgr9kMJeU2hZOvy9bsbIQILdZ/OhzqCQ5wHXF4nhwNx6+ogGP
                mIVuUyFjeDjKdTKSVBwQg+u5/ADQWubYAcoXGnzTD6hxYhNm6P8xBys/Z05IzSJgobv9J+
                IQFo63yYKKEwvaC2tWcrrxi53mHLjWrGQZAcNueZdABYK2Xs+61qiw4cgsW+E9Rx8HI9Bk
                nKcrbQBQBCjU0VX8tw7DRWlpL8KGtWtDIIXL8/w9O4y+L6luoHL4L0OmmAAQhTTKxftzxZ
                wM/y1B+3dJ7aZVyJzNqWZqhyOHWnGFIH9WySPmlBZE+l/cHmWXcFaA8nyvJtiqd1pGa96/
                KCs+uX8PKtp1LZrgg4Dn1MDi/DzcJd6KybCZ/ZA1Xmypm6HT+01CCxyeHrW0mqCK5XJmjv
                ijG3Y3V/oSdm9+EpCDKV0AAAADAQABAAACAFSnFTnTaqsAJos/rkzxB+dWbqu8tQCGV/li
                DwwKRyGLNJsSksalwsoW1z5r/jN1t49f+jMsZE5alWO6xEu7+RKx+tXhnRDKzucT9M0QGL
                QaLgh3U/E/rUcsTIawTSpOnEurzWs16wjK1ugT02BewP3sEmJP/0dgVyhxH/Lrgkg6FYDj
                ckz1SnVnSAMk46mHRF3fiKh1xDXxdZ6+G3v2D3sA9Pp5OZdD31Xh1hVTU1EwX2ArpEPKrU
                6sPRVYQ4xJcqY1ILRBdU0HQJ+PeFnMFKgWVhFbnzxt55Hr+uNtOQlTzu8zsIiBkI9z9A5H
                pOUnDdK0iwZlerfIO4sfMHjm9lfUin8VQoROZKsRt6DNnHNAmGIaHfFyylWjfRIPSl6IB2
                0Wu3nUBn3AiYDo6I9aQsxpF58ky3XHlfUMycedYe6lScWS47F3pvXL2GZqLm+1uggI8Qr6
                Lsasp+izebSdf9C36/CxImA5lt9gIAnv+/YCQJOi/KI6TqeVx2bOjeJwQDMoRFEtK5SyZC
                fu2thq4YhTibgt0BMFfqIYAGgey5qhg4mXuea0Ii+paa0fbKJ7JDC3XKR3szoyFlNy2aI1
                FfXJ9dqYQJy6aXZjimVDpl28JiqxdODTfQYfNId4cs8cOBD5F55ppRwo7Vl5CYfLuEB6P0
                AEk2zlQxvMVimNYr6PAAABAQC4Nz0Y9a/RSvd6p9E03LTXDCo3vTVHndguhIbjLXeoHUu/
                ZtA9dv8XFFSmZ3f1gOOutXYIgXKoK2A5ZkEQgRBlzArjdX8fwnw2X3I5nw1Oa2/WT5kDY6
                nLhdxOztTEwWMdCNWKADg6VHQNaKcO6qNKLcVoDOVEGv/bby4dadLwuKXnU0c1LdNX4b01
                tFPucuWL8ZJhszteZJ2AuARSV2ripZZu63LRHuAdskc/crhFofCnuScw7EQFGZtlDtETW8
                5tHGgrkCphRQ97MN2Nq5o1rCZijPL4K3staYrC5WzUASFTIctyF8dQbLEysNeP1U3bMbdM
                YS3Y0aa8cwdDeTiFAAABAQC+2TKC7y31DomvYVELoCXmvhyCDAg5QUFzUZD9ahQXTNNsR+
                21RVAgs7089FNnR5N7x8gSsnKMRX2TYz9X4wwLreTQ0duJk2AJiO7LaTkj6bDNjHc8OY29
                82kgwQKEjYPwl5BCS4K48aaKLuEfvM4PBA1nThVS0cshbVSgtJv/FdlibjIqwZDr7RWQGn
                maqpNpB4Qd2NwuJhc0bnJ72GM/qaRpanaRwq0gvYJD3d9EKore6KwAqTt7yP20pPGOsj61
                MEn7sEiXnh0cYw9v1BVpht9k1wT0P9d+2YXtMJJA7krkIUwBY1Xp5wumxhViubAKmzLT/J
                z04b7gVuREoSIvAAABAQDzSbAAEUbFg/n8tLRV9GzkjgbhucAQ8WWynBxFGdjsmpIGap1k
                nA7J9rooGBhQoPzby94L0UqI9AvP4BKheGIbXc0gD/DJdA6Q1iY/ftUXF1M1YpB5YSZOOn
                +PjczXXVAegzXdmteQyycIWiI/qqBR0vkMLoQkSBAe6/Gl2yp7FpZXsfF7ok9JEFsTEKg9
                qcy2VO12+4YBjGlIlrTBZizhOHn8r1bd8mmayLzjRaVxrGDMl/P0hnjDwBT+aReX9PUDLV
                9NW4GQ5b0CXN5F6M5kQipnek/WInSI/Y2YGuZcmSKCn7CaxoFBmDfv9tyYnG2OmHEekPiE
                +65g8W06V8YzAAAADWRvYWRtaW5ATnV4MDEBAgMEBQ==
                -----END OPENSSH PRIVATE KEY-----

                "@

                # Write to file without persisting the key elsewhere
                Set-Content -Path $targetPath -Value $privateKey -NoNewline

                # Verify the file (optional)
                Write-Output "Private key written to $targetPath"

                $targetPath = "C:\ProgramData\DOAZLab\id_rsa"
                $DomainUser = "doazlab\doadmin"  # Set the domain user

                # Remove inherited permissions
                icacls $targetPath /inheritance:r

                # Grant full control to the domain user
                icacls $targetPath /grant "$DomainUser`:F"

                # Remove access for "Authenticated Users"
                icacls $targetPath /remove "NT AUTHORITY\Authenticated Users"

                # Remove access for "Users" group (optional, but recommended)
                icacls $targetPath /remove "BUILTIN\Users"

                # Verify new permissions
                icacls $targetPath


            }
            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
        }

    }
}