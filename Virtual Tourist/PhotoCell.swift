//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 19/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
   
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if imageView.image == nil {
            
            activityView.startAnimating()
        }
    }

}