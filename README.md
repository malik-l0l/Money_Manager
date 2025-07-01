# todo

provide you with the complete Flutter project structure and all the Dart code you need for your money manager app! You'll need to create this in your local Flutter development environment.
Add dependencies to your pubspec.yaml:


now please do these modifications :

add a new page to manage transaction between people, make a seperate database and page for that

here the popup should ask 3 things : toggle "give" or "take" amount text field name of the person text field reason text field save button
if i give 30 rs to "sam" it should show "take 30 from sam"
if take 30 rs from "sam" it should show "give 40 back to sam"

store the history by each person


but how can i add people transactions, it is not visible. modify main.dart or files in  screens/


when i give money to someone reduce it from the main balance in the main page. also add an entry in history in main page : give money for "<name>"  for "<reason>"

when i take money from someone add it to the main balance in the main page. also add an entry in history in main page : take money from "<name>"  for "<reason>"



please do these modifications :

remove quick actions section.

place people manager icon in the top, near  settings  and monthly summary icon.

when i give someone money it need to be reduced automatically from the main_balance in the home screen. similarly hen i take money from it need to be added automatically to the main_balance in the home screen.

when i press tick mark from the phone keyboard automatically go to the next text field - to improve user experience,


please fix this bug i saw :

when i add an income "500" current balance = 500
when i give "sam" 30 the current balance is now = 440, which is wrong because 500-30=470
i think it is substracting twice please fix the issue




now please do these modifications :

in the people manager window remove 'Net Balance',

instaed 'total given' and 'total taken' replace it with "You owe" which shows the amount you owe to people, "owes you" which is the amount the peoples owe you

when i lock my phone in people transaction screen, when i unlock the UI just crashes, the text are scattered if this bug is fixable, please fix it too

## cancelled

- place toggle inside transaction to add people transaction ---> cancelled
- insufficient fund ---> cancelled , can be negative balance

### DONE

- auto appear name in Person Name 
- automatic cursor go to amount, expense first income second
- in setting automatic scroll up add transaction window,
- dlt from main screen to delete from people screen
- make people transaction button in home screen

### TODO

- fix crash issue
- implement chart
- messages from bottom up -remove it 

```

now please do these modifications : 
- in home screen we have to FABs "+ Add Transaction" and "people transaction" buttons, please modify them.
like this, place []"Icons.person_add" on left] and ["+" icon on right] in bottom-center side by side of the home screen,
if there is a better way than this to implement this which will greatly improve User Experience, then please do that 

- make the "Recent Transactions" infinitely scrollable till the first transaction, when i scroll down fade in FAB buttons, when i scroll up show them back, use simple nice animations.

- place the "Expense" on the left side and  "Income" on the right side of "Add transaction modal"

- use another way to display error,danger,info,etc messages in home screen.
- place the amount field on the top and name field under it in the people_transaction_modal
- when the setting "Auto focus amount field is" is on, focus in the people transaction modal too, currently it is available only in "add_transaction_modal",

- show date just like this "dd-mm-yy HH:MM AM/PM [in 12 hr format]" currently it is showing "today" "yesterday"...

- fix the crash issue in people manager screen, when i people screen, and close the phone, and when i reopen it the letters,words are scrambled. please fix this issue


```