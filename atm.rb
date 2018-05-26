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

  private

  def input_pin
    print 'Please Enter Your Account Number: '
    pin = gets.to_i
  end

  def input_password
    print 'Enter Your Password: '
    password = gets.chomp
  end

  def check_auth! 
    if ACCOUNTS.has_key?(pin) && password == ACCOUNTS[pin]['password']
      @user_data = { :name => ACCOUNTS[pin]['name'], :balance => ACCOUNTS[pin]['balance'] }
      puts 'Cheking info....'
      sleep 0.3
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

  def menu
    [
      "Please Choose From the Following Options:",
      "1. Display Balance",
      "2. Withdraw",
      "3. Log Out",
      "Enter chiose: "
    ]
  end  

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

  def validate_atm!
    Authorize.new.user_data.each { |k,v| instance_variable_set("@#{k}", v) }
    @valid = true
    puts "Hello,#{name}!"
    puts menu.join("\n")
    choise
  end

  def display_balance
    puts "Your Current Balance is ₴#{@balance}"
    choise
  end

  def notes_sum hsh
    hsh.inject(0) { |sum, (note, qty)| sum += note * qty } 
  end

  def withdraw 
    print 'Enter Amount You Wish to Withdraw: '
    amount = gets.to_i
    check_withdraw(amount)
  end  

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

  def logout
    puts "Logged out"
    atm = Atm.new
  end

end




class InvalidLoginInput < StandardError; end




atm = Atm.new
