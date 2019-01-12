class Home 
   
   MAX_HUE = 65535
   MAX_BRI = 254
   
   def get_digest_values
       
   end
   
   def self.calculate_hue(val)
      hue_val = (MAX_HUE/100)*val.to_i
      return hue_val.round
   end
   
   def self.calculate_bri(val)
      bri_val = (MAX_BRI/100)*val.to_i
      return bri_val.round
   end
   
   def self.calculate_val_from_hue(hue)
      val = ((hue.to_i/MAX_HUE.to_f)*100.0).round
      return val
   end
   
   def self.calculate_val_from_bri(bri)
      val = ((bri.to_i/MAX_BRI.to_f)*100.0).round
      return val
   end
end