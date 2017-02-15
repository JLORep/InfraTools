for /f "tokens=*" %%i in ('dsget group "cn=Groups to Protect,ou=ResourceGroups,ou=Groups,ou=MMU,dc=ad,dc=mmu,dc=ac,dc=uk" -members') do dsacls %%i /D "AD\User Account Operators":RPWP;member;group /P:y /I:S
dsget group "cn=Groups to Protect,ou=ResourceGroups,ou=Groups,ou=MMU,dc=ad,dc=mmu,dc=ac,dc=uk" -members | dsmod group "cn=Protected Groups,ou=ResourceGroups,ou=Groups,ou=MMU,dc=ad,dc=mmu,dc=ac,dc=uk" -addmbr -c
dsget group "cn=Groups to Protect,ou=ResourceGroups,ou=Groups,ou=MMU,dc=ad,dc=mmu,dc=ac,dc=uk" -members | dsmod group "cn=Groups to Protect,ou=ResourceGroups,ou=Groups,ou=MMU,dc=ad,dc=mmu,dc=ac,dc=uk" -rmmbr -c
pause


