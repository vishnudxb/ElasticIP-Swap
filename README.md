
#Attach and Detach Public IP

*This script is used for detach elastic ip from one server and attach it to the secondary private ip of the other server*

#For example
#Script Usage for detaching Public IP from lb11 and attach it to the secondary private IP of lb12

  
  ```
user@machine:~./ip-swap.sh --alter swap --from lb11 --to lb12

  ```

#To revert the changes

  
  ```
user@machine:~./ip-swap.sh --alter revert --from lb11 --to lb12

  ```
