from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.customer import CustomerCreate, CustomerUpdate, CustomerResponse
from app.services.customer_service import CustomerService

router = APIRouter(prefix="/customers", tags=["customers"])


@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def create_customer(customer: CustomerCreate, db: Session = Depends(get_db)):
    """Create a new customer"""
    service = CustomerService(db)
    
    # Check if email already exists
    existing = service.get_customer_by_email(customer.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    return service.create_customer(customer)


@router.get("/", response_model=List[CustomerResponse])
def list_customers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List all customers"""
    service = CustomerService(db)
    return service.list_customers(skip=skip, limit=limit)


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer(customer_id: int, db: Session = Depends(get_db)):
    """Get customer by ID"""
    service = CustomerService(db)
    customer = service.get_customer(customer_id)
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found"
        )
    
    return customer


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(customer_id: int, customer_data: CustomerUpdate, db: Session = Depends(get_db)):
    """Update customer"""
    service = CustomerService(db)
    
    # Check if email is being updated and if it already exists
    if customer_data.email:
        existing = service.get_customer_by_email(customer_data.email)
        if existing and existing.id != customer_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    customer = service.update_customer(customer_id, customer_data)
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found"
        )
    
    return customer


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_customer(customer_id: int, db: Session = Depends(get_db)):
    """Delete customer"""
    service = CustomerService(db)
    success = service.delete_customer(customer_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found"
        )
