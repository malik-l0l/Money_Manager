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

#### 01-07-25

- in home screen we have to FABs "+ Add Transaction" and "people transaction" buttons, please modify them.
like this, place []"Icons.person_add" on left] and ["+" icon on right] in bottom-center side by side of the home screen,
if there is a better way than this to implement this which will greatly improve User Experience, then please do that 

- make the "Recent Transactions" infinitely scrollable till the first transaction, when i scroll down fade in FAB buttons, when i scroll up show them back, use simple nice animations.

- place the "Expense" on the left side and  "Income" on the right side of "Add transaction modal"

- use another way to display error,danger,info,etc messages in home screen.
- place the amount field on the top and name field under it in the people_transaction_modal
- when the setting "Auto focus amount field is" is on, focus in the people transaction modal too, currently it is available only in "add_transaction_modal",

- show date just like this "dd-mm-yy HH:MM AM/PM [in 12 hr format]" currently it is showing "today" "yesterday"...

#### 01-07-25

- removed unwanted + in person_details
- fixed owe claim not persisting issue
- fixed owe claim not in "You Owe" "owe you" fields
- improved people manager icons 
- improved settled design - planning to expand this design to others


#### 12-01-25

- in Transaction History in person detail screen, remove "Pay <money> back to <name>" and "Collect <money> from <name>" from the cards, also remove "main balance: <money>" from the cards

- place "owes you" on the left side and "you owe" on the right side in people manager

- remove + prefix from income cards

- i really liked the design,theme of settled cards in people manager, implement the same design,theme to all other cards in home screen and people manager screen, for income use green theme, for expense use red theme in home_screen, for "owes you" green theme, for "you owe" red theme and for settled grey theme in people manager screen, for "owe" use current orange like theme, for claim use the current blue like theme in person_detail screen. also improve the card design in monthly summary

- make this new theme "theme 1" and old theme "theme 2" in the settings, where user can switch between settings, make theme 1 as default. make this settings persist even if i close and reopen the app

- in theme 1 do this modification : the theme of "You owe" "owes you" "total income" "total expenses" must be like the current balance card on the home screen, for "you owe" and "total expenses" in red theme , and others in green theme

- please give me errorless code

- modify home screen, place date outside


### TODO

```
Analyze the code in lib folder very carefully and please do these modifications in the dart code :
- please give me errorless code 


```

- fix crash issue
- implement chart









```

now please do these modifications : 

- quotes tips on the top, where "good <> <name> is placed"

- research Breadcrumb navigation for complex flows

- Data Visualization - Mini charts showing spending trends

- Progressive onboarding cards showing app value proposition

- Contextual tips based on time of day/week

- 85% higher new user activation through guided first actions, Reduces abandonment during initial setup phase

- Balance update animations with positive/negative feedback

- widget

- long press "+" show food, travel, or 4 types of transaction


- fix the crash issue in people manager screen, when i people screen, and close the phone, and when i reopen it the letters,words are scrambled. please fix this issue


```