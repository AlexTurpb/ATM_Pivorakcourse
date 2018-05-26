require 'yaml'

$config = YAML.load_file(ARGV.first || 'config.yml')

class Authorize

  ACCOUNTS = $config ['accounts']

  attr_reader :pin, :password
  attr_accessor :user_data
  def initialize
    @pin = input_pin
    @password = input_password
    @user_data

    check_auth!
  end

  #just some simple 'console output animation'
  def visual_dot str
    print str; 7.times { print "."; sleep 0.2 }; puts
  end

  private

  #accepts user pin input, invoked Authorize.new initialize
  def input_pin
    print 'Please Enter Your Account Number: '
    pin = gets.to_i
  end

  #accepts user password input, invoked Authorize.new initialize
  def input_password
    print 'Enter Your Password: '
    password = gets.chomp
  end

  #cheks user input with values in config.yml, writes user data to Authotize instance if true, raises error on false
  #further errors are implemented with puts operator, as it makes console output more nicer IMHO 
  def check_auth! 
    if ACCOUNTS.has_key?(pin) && password == ACCOUNTS[pin]['password']
      @user_data = { :name => ACCOUNTS[pin]['name'], :balance => ACCOUNTS[pin]['balance'] }
      visual_dot('Cheking info')
    else
     raise InvalidLoginInput, 'invalid login or password'
    end
  end

end

class Atm

  BANKNOTES = $config['banknotes']
  MAX_WITHDRAW = 90_000

  attr_reader :name
  attr_accessor :balance, :valid, :stash, :user_transaction
  def initialize name = '', balance = 0, valid = false, stash = BANKNOTES, user_transaction = {}
    @name = name
    @balance = balance
    @valid = valid
    @stash = stash
    @user_transaction = user_transaction

    validate_atm!
  end

  #contains menu options
  def menu
    [
      "Please Choose From the Following Options:",
      "1. Display Balance",
      "2. Withdraw",
      "3. Log Out",
      "Enter chiose: "
    ]
  end  

  #accepts user input and provides 'menu-linked' metods execution
  def choise
    loop do
      choise = gets.to_i
      case choise
        when 1 then display_balance
        when 2 then withdraw
        when 3 then logout 
        else
          print "Invalid command!!!\nEnter chiose: "
          choise
      end
      break if choise == 3
    end     
  end

  
  private

  #creates Authorize instance and collects user_data for Atm instance initialization, then greets user and displays menu
  def validate_atm!
    Authorize.new.user_data.each { |k,v| instance_variable_set("@#{k}", v) }
    @valid = true
    puts "Hello,#{name}!"
    puts menu.join("\n")
    choise
  end

  ########################## MENU METHODS ##########################

  #(menu-1) shows users balance
  def display_balance
    puts "Your Current Balance is ₴#{@balance}"
    choise
  end

  #(menu-2) accepts amount input, starts withdraw related check methods 
  def withdraw 
    print 'Enter Amount You Wish to Withdraw: '
    amount = gets.to_i
    check_withdraw(amount)
  end

  #(menu-3) ends current user work with ATM and allows to start new one after
  def logout
    puts "Logged out"
    atm = Atm.new
  end

  ########################## MENU METHODS ##########################


  #amount check scenarios, conslole error output 
  def check_withdraw amount
    
    if amount > MAX_WITHDRAW
      puts "ERROR: INSUFFICIENT FUNDS!! PLEASE ENTER A DIFFERENT AMOUNT:"
      withdraw
    elsif amount > balance
      puts "ERROR: #{name.capitalize} YOUR BALANCE IS TOO LOW! PLEASE ENTER A DIFFERENT AMOUNT:"    
      withdraw
    elsif amount > notes_sum(stash)
      puts "ERROR: THE MAXIMUM AMOUNT AVAILABLE IN THIS ATM IS ₴#{notes_sum(stash)}"
      withdraw
    else
      return_cash(amount, user_transaction)  
    end

  end

  #calculates notes to compose amount from ATM stash, updates user balance, ATM stash
  def return_cash amount, user_transaction
    stash.each do |note, qty|
      
      if amount >= note * qty
        user_transaction.store(note, qty)
        amount -= (note * qty)
      else
        user_transaction.store(note, amount.divmod(note).first)
        amount -= note * amount.divmod(note).first
      end
          
    end

      if amount != 0
        puts "ERROR: THE AMOUNT YOU REQUESTED CANNOT BE COMPOSED FROM BILLS AVAILABLE IN THIS ATM. PLEASE ENTER A DIFFERENT AMOUNT: "
        withdraw
      else
        @balance -= notes_sum(user_transaction)  
        @stash.merge!(user_transaction) {|note, stash_qty, withdrawn| stash_qty - withdrawn }
        
        puts "#{name} please take your money! Balance is: #{balance} "
        choise
      end  

  end

  #help method provides sum of all notes contained in note related hashes
  def notes_sum hsh
    hsh.inject(0) { |sum, (note, qty)| sum += note * qty } 
  end

end

class InvalidLoginInput < StandardError; end

atm = Atm.new