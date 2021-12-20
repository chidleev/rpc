// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

contract DPS {
    struct Driver {
        string name;
        bool haveLicense;
        uint licenseId;
        uint exp;
    }

    struct Car {
        uint category;
        uint price;
        uint exp;
    }

    struct License {
        uint validity;
        bool category_A;
        bool category_B;
        bool category_C;
        address payable owner;
    }

    mapping(address => uint) role; //1 - водила 2 - мент
    mapping(uint => License) license;
    mapping(address => Car) car;
    mapping(address => Driver) driverInfo;
    mapping(address => string[]) messages;

    address payable default_address = 0x0000000000000000000000000000000000000000;

    modifier is_reg() {
        require(role[msg.sender] != 0, "You dont have an account!");
        _;
    }

    modifier have_license() {
        require(driverInfo[msg.sender].haveLicense, "You dont have a license!");
        _;
    }

    constructor() {
        license[0] = License(1610312400, true, false, false, default_address);
        license[111] = License(1746997200, false, true, false, default_address);
        license[222] = License(1599858000, false, false, true, default_address);
        license[333] = License(1802466000, true, false, false, default_address);
        license[444] = License(1796936400, false, true, false, default_address);
        license[555] = License(1876942800, false, false, true, default_address);
        license[666] = License(1901134800, true, false, false, default_address);

        /*role[] = 2;
        driverInfo[] = Driver("Ivanov Ivan Ivanovich", false, 0, 2);

        role[] = 1;
        driverInfo[] = Driver("Semenov Semen Semenovich", false, 0, 5);
        
        role[] = 1;
        driverInfo[] = Driver("Petrov Petr Petrovich", false, 0, 10);*/
    }

    
    function reg_driver(string memory _name, uint _exp) public {
        require(role[msg.sender] == 0, "Registration error: You already have an account!");
        driverInfo[msg.sender] = Driver(_name, false, 0, _exp);
        role[msg.sender] = 1;
        send_message("Registration successfully!");
    }

    function reg_license(uint _licenseId, uint _validity, uint _category) public is_reg {
        if (driverInfo[msg.sender].haveLicense) {
            send_message("Registration license error: You already have a license!"); 
            return();
        }

        if (license[_licenseId].validity == 0) {
            send_message("Registration license error: License does not exist!"); 
            return();
        }

        if (license[_licenseId].validity != _validity) {
            send_message("Registration license error: Invalid expiration date!"); 
            return();
        }

        if ((_category < 1) || (_category > 3)) {
            send_message("Registration license error: Your category does not exist!"); 
            return();
        }

        if ((!license[_licenseId].category_A && _category == 1) || 
            (!license[_licenseId].category_B && _category == 2) || 
            (!license[_licenseId].category_C && _category == 3)) {
            send_message("Registration license error: Your license does not have your category!"); 
            return();
        }

        if (license[_licenseId].owner != default_address) {
            send_message("Registration license error: Your license already have an owner!"); 
            return();
        }

        driverInfo[msg.sender].haveLicense = true;
        driverInfo[msg.sender].licenseId = _licenseId;
        license[_licenseId].owner = msg.sender;
        send_message("Registration license successfully!");
    }

    function add_category(uint _category) public is_reg have_license {
        License memory _license = license[driverInfo[msg.sender].licenseId];

        if ((_category < 1) || (_category > 3)) {
            send_message("Adding category error: Your category does not exist!"); 
            return();
        }
        
        if (_category == 1) {
            if (_license.category_A) {
                send_message("Adding category error: Your license already have A category!"); 
                return();
            }
            license[driverInfo[msg.sender].licenseId].category_A = true;
            send_message("Adding A category successfully!");
        }

        if (_category == 2) {
            if (_license.category_B) {
                send_message("Adding category error: Your license already have B category!"); 
                return();
            }
            license[driverInfo[msg.sender].licenseId].category_B = true;
            send_message("Adding B category successfully!");
        }

        if (_category == 3) {
            if (_license.category_C) {
                send_message("Adding category error: Your license already have C category!"); 
                return();
            }
            license[driverInfo[msg.sender].licenseId].category_C = true;
            send_message("Adding C category successfully!");
        }
    }

    function renewal_license() public is_reg have_license {
        License memory _license = license[driverInfo[msg.sender].licenseId];

        if (_license.validity - block.timestamp > 2667600 && block.timestamp < _license.validity) {
            send_message("Renewal license error: More than a month before expiration!"); 
            return();
        }

        license[driverInfo[msg.sender].licenseId].validity += 31525200;
        send_message("Renewal license successfully!");
    }

    function reg_car(uint _category, uint _price, uint _exp) public is_reg have_license {
        License memory _license = license[driverInfo[msg.sender].licenseId];

        if ((_category < 1) || (_category > 3)) {
            send_message("Registration car error: Your category does not exist!"); 
            return();
        }

        if ((!_license.category_A && _category == 1) || 
            (!_license.category_B && _category == 2) || 
            (!_license.category_C && _category == 3)) {
            send_message("Registration car error: Your license does not have your car category!"); 
            return();
        }

        car[msg.sender] = Car(_category, _price, _exp);
        send_message("Registration car successfully!");
    }


    function get_driver_info() public view is_reg returns(string memory, uint, uint) {
        return(driverInfo[msg.sender].name, driverInfo[msg.sender].licenseId, driverInfo[msg.sender].exp);
    }

    function get_license_info() public view is_reg have_license returns(uint, bool, bool, bool) {
        License memory _license = license[driverInfo[msg.sender].licenseId];
        return(_license.validity, _license.category_A, _license.category_B, _license.category_C);
    }

    function get_car_info() public view is_reg returns(uint, uint, uint) {
        require(car[msg.sender].category > 0, "You dont have a car..");
        return(car[msg.sender].category, car[msg.sender].price, car[msg.sender].exp);
    }

    function get_last_message() public view is_reg returns(string memory) {
        if (messages[msg.sender].length - 1 < 0) return("You have no messages..");
        else return(messages[msg.sender][messages[msg.sender].length - 1]);
    }

    function send_message(string memory message) private {
        messages[msg.sender].push(message);
    }
}