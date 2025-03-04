Config = {}

Config.SpeedLimits = {
    City = 80,
    Freeway = 110,
    Residence = 50
}

Config.DMV = {
    { 
        Pos   = {x = 239.471, y = -1380.960, z = 32.741}
        Licenses = { 'bike', 'car'},
        VehicleSpawnPoint =  = {x = 249.409, y = -1407.230, z = 30.4094, h = 317.0},
        Ped = ''
    },
    { 
        Pos   = {x = 239.471, y = -1380.960, z = 32.741}
        Licenses = { 'bike', 'car', 'truck'},
        VehicleSpawnPoint =  = {x = 249.409, y = -1407.230, z = 30.4094, h = 317.0},
        Ped = ''
    },
}

Config.Licenses = {
    Car = {
       Price = 950, 
       Model = ''
       Questions = {
            {
                Text = "",
                Options = {
                    { text = "", correct = false}
                    { text = "Correct", correct = true}
                    { text = "", correct = false}
                }
            },
            {
                Text = "",
                Options = {
                    { text = "", correct = false}
                    { text = "Correct", correct = true}
                    { text = "", correct = false}
                }
            },
            {
                Text = "",
                Options = {
                    { text = "", correct = false}
                    { text = "Correct", correct = true}
                    { text = "", correct = false}
                }
            }
       }
    },
    Bike = {
        Price = 1050, 
        Model = ''
        Questions = {
             {
                 Text = "",
                 Options = {
                     { text = "", correct = false}
                     { text = "Correct", correct = true}
                     { text = "", correct = false}
                 }
             },
             {
                 Text = "",
                 Options = {
                     { text = "", correct = false}
                     { text = "Correct", correct = true}
                     { text = "", correct = false}
                 }
             },
             {
                 Text = "",
                 Options = {
                     { text = "", correct = false}
                     { text = "Correct", correct = true}
                     { text = "", correct = false}
                 }
             }
        }
    }
    Truck = {
        Price = 2000, 
        Model = ''
        Questions = {
             {
                 Text = "",
                 Options = {
                     { text = "", correct = false}
                     { text = "Correct", correct = true}
                     { text = "", correct = false}
                 }
             },
             {
                 Text = "",
                 Options = {
                     { text = "", correct = false}
                     { text = "Correct", correct = true}
                     { text = "", correct = false}
                 }
             },
             {
                 Text = "",
                 Options = {
                     { text = "", correct = false}
                     { text = "Correct", correct = true}
                     { text = "", correct = false}
                 }
             }
        }
    }
}