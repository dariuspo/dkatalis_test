# DKatalis Take Home Test

## Darius Sandatinus _ One Day Recruitment Program

This repository is contains test for dkatalist

## DEMO:
[Deployed Web Application](https://dkatalis-7cfd1.web.app/)

## Installation

This project requires [Flutter](https://docs.flutter.dev/get-started/install) to be installed.
For run in chrome...

```sh
flutter run -d chrome
```

## Commands Available

The application support these command

| Command | Description | Validation |
| ------ | ------ | ------ |
| login [username] | to login user | need logout first, username cannot have space
| logout | logout current user | need login first
| deposit [amount] | added balance to current user | need login first, amount need to be valid number, cannot 0
| transfer [username] [amount] | transfer certain amount to specified user | need login first, amount need to be valid number, cannot 0, username need to be registered first, cannot send to own name
| withdraw [amount] | deduct balance from current user | need login first, amount need to be valid number, cannot 0, withdraw amount cannot exceed current balance


## Ambiguity
- Username is not case sensitive means alice is same with Alice
  -- this is default behavior many application when we login, username (usually email always not case sensitive)
- Commands is case sensitive
  -- command need to be case sensitive to more have robust system against typo
- User have surplus owe from target user and surplus balance:
  -- when do the transfer it will deduct the owe first then the balance
- Cannot withdraw more than current balance
  -- this is to prevent negative balance, that currently use owe, but withdraw is don't have any owe name
- When having owe to more than 1 people, deposit will pay the first in the list.
  -- this is because we need to pay the oldest transaction first 
