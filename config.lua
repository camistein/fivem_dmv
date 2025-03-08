Config = {}

Config.ShowMarker = true
Config.DrawMarker = 10
Config.MaxRetries = {
    Exam = 3,
    Practical = 2
}

Config.Language = 'sv'

Config.SpeedLimits = {
    City = 80,
    Highway = 110,
}

Config.DMV = {
    { 
        Pos = vector3(109.239563, -1089.019775, 28.28),
        Licenses = 'Bike,Car,Truck',
        VehicleSpawnPoint = vector3(106.127472, -1069.186768, 29.296753),
        Blip = {
            Enabled = true,
            Label = 'DMV',
            Sprite = 498,
            Color = 42,
            Scale = 1.1
        },
        Ped = {
            Pos   = vector3(109.239563, -1089.019775, 29.296753),
            Model = `u_f_m_debbie_01`,
        }
    }
}

Config.Licenses = {
    Car = {
       Price = 1, 
       Model = 'asbo',
       MinimumCorrectExam = 4,
       QuestionnaireAmount = 5, 
    },
    Bike = {
        PrerequiredLicense = 'car',
        Price = 1050, 
        ModelHash = 'bati',
        MinimumCorrectExam = 4,
        QuestionnaireAmount = 5, 
    },
    Truck = {
        PrerequiredLicense = 'car',
        Price = 2000, 
        ModelHash = 'flatbed',
        MinimumCorrectExam = 4,
        QuestionnaireAmount = 5, 
    }
}